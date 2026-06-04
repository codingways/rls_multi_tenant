# frozen_string_literal: true

require 'uri'

# Harness for the real-PostgreSQL integration suite.
#
# Connects through plain ActiveRecord (no Rails boot) to a database described by
# DATABASE_URL (defaults to the local docker container used in development).
# Creates the privileged/unprivileged roles and the schema the RLS specs need,
# and lets examples switch the active connection between roles.
module IntegrationDB
  module_function

  ADMIN_URL = ENV['DATABASE_URL'] || 'postgres://postgres:postgres@127.0.0.1:55432/rls_test'

  APP_ROLE      = 'rls_app'       # NOSUPERUSER NOBYPASSRLS — RLS is enforced
  BYPASS_ROLE   = 'rls_bypass'    # BYPASSRLS granted directly
  GROUP_ROLE    = 'rls_group'     # NOLOGIN, BYPASSRLS — granted to a member
  MEMBER_ROLE   = 'rls_member'    # inherits BYPASSRLS from rls_group
  ROLE_PASSWORD = 'app_password'

  def uri
    @uri ||= URI.parse(ADMIN_URL)
  end

  def base_config
    {
      adapter: 'postgresql',
      host: uri.host,
      port: uri.port,
      database: uri.path.sub(%r{\A/}, '')
    }
  end

  def admin_config
    base_config.merge(username: uri.user, password: uri.password)
  end

  def role_config(role)
    base_config.merge(username: role, password: ROLE_PASSWORD)
  end

  # Lazily determine whether the integration database is reachable. When it is
  # not, the suite excludes :integration examples instead of failing.
  def available?
    return @available if defined?(@available)

    @available = begin
      conn = PG.connect(ADMIN_URL)
      conn.close
      true
    rescue PG::Error, StandardError
      false
    end
  end

  def admin_exec(sql)
    conn = (@admin_conn ||= PG.connect(ADMIN_URL))
    conn.exec(sql)
  end

  def connect_admin!
    ActiveRecord::Base.establish_connection(admin_config)
  end

  def connect_as!(role)
    ActiveRecord::Base.establish_connection(role_config(role))
  end

  # Create all roles, the schema and the RLS policy. Idempotent.
  def setup!
    create_roles!
    create_schema!
    enable_rls!
    grant_privileges!
  end

  def create_roles!
    [APP_ROLE, BYPASS_ROLE, MEMBER_ROLE].each do |role|
      admin_exec(<<~SQL)
        DO $$BEGIN
          IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '#{role}') THEN
            CREATE ROLE #{role} LOGIN PASSWORD '#{ROLE_PASSWORD}';
          END IF;
        END$$;
      SQL
    end

    admin_exec(<<~SQL)
      DO $$BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '#{GROUP_ROLE}') THEN
          CREATE ROLE #{GROUP_ROLE} NOLOGIN;
        END IF;
      END$$;
    SQL

    admin_exec("ALTER ROLE #{APP_ROLE} NOSUPERUSER NOBYPASSRLS")
    admin_exec("ALTER ROLE #{BYPASS_ROLE} NOSUPERUSER BYPASSRLS")
    admin_exec("ALTER ROLE #{GROUP_ROLE} NOSUPERUSER BYPASSRLS")
    admin_exec("ALTER ROLE #{MEMBER_ROLE} NOSUPERUSER NOBYPASSRLS INHERIT")
    admin_exec("GRANT #{GROUP_ROLE} TO #{MEMBER_ROLE}")
  end

  def create_schema!
    admin_exec('DROP TABLE IF EXISTS posts CASCADE')
    admin_exec('DROP TABLE IF EXISTS tenants CASCADE')
    admin_exec(<<~SQL)
      CREATE TABLE tenants (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        name text NOT NULL,
        subdomain text
      )
    SQL
    admin_exec(<<~SQL)
      CREATE TABLE posts (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id uuid NOT NULL REFERENCES tenants(id),
        title text,
        created_at timestamp,
        updated_at timestamp
      )
    SQL
  end

  # Exercise the gem's own helper to install the policy, connected as admin.
  def enable_rls!
    connect_admin!
    RlsMultiTenant::RlsHelper.enable_rls_for_table('posts')
  end

  def grant_privileges!
    [APP_ROLE, BYPASS_ROLE, MEMBER_ROLE].each do |role|
      admin_exec("GRANT SELECT, INSERT, UPDATE, DELETE ON tenants TO #{role}")
      admin_exec("GRANT SELECT, INSERT, UPDATE, DELETE ON posts TO #{role}")
    end
  end

  # Remove all rows; runs as admin (superuser bypasses RLS) so it always works.
  def truncate!
    admin_exec('TRUNCATE posts, tenants CASCADE')
  end

  def seed_tenant!(name:, subdomain: nil)
    row = admin_exec(
      "INSERT INTO tenants (name, subdomain) VALUES " \
      "('#{name}', #{subdomain ? "'#{subdomain}'" : 'NULL'}) RETURNING id"
    ).first
    row['id']
  end

  def seed_post!(tenant_id:, title:)
    admin_exec(
      "INSERT INTO posts (tenant_id, title) VALUES ('#{tenant_id}', '#{title}')"
    )
  end
end

# Define the ActiveRecord models the integration suite uses. They are plain
# models wired through the gem's concerns.
if IntegrationDB.available?
  class Tenant < ActiveRecord::Base
    include RlsMultiTenant::Concerns::TenantContext
  end

  class Post < ActiveRecord::Base
    include RlsMultiTenant::Concerns::MultiTenant
  end
end

RSpec.configure do |config|
  unless IntegrationDB.available?
    config.filter_run_excluding(:integration)
    warn '[integration] DATABASE_URL not reachable — skipping :integration specs'
  end

  config.before(:suite) do
    if IntegrationDB.available?
      RlsMultiTenant.tenant_class_name = 'Tenant'
      RlsMultiTenant.tenant_id_column = :tenant_id
      IntegrationDB.setup!
    end
  end

  config.before(:each, :integration) do
    IntegrationDB.truncate!
    IntegrationDB.connect_as!(IntegrationDB::APP_ROLE)
  end
end
