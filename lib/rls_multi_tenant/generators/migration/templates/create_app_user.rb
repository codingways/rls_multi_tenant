class CreateAppUser < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def up
    app_user = ENV['<%= RlsMultiTenant.app_user_env_var %>']
    app_password = ENV['POSTGRES_APP_PASSWORD']

    # Create user with RLS privileges in PostgreSQL
    execute <<-SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '#{app_user}') THEN
          CREATE ROLE #{app_user} WITH LOGIN PASSWORD '#{app_password}';
        END IF;
      END
      $$;
    SQL

    # Grant basic permissions to the user
    execute "GRANT CONNECT ON DATABASE #{ActiveRecord::Base.connection.current_database} TO #{app_user};"
    execute "GRANT USAGE ON SCHEMA public TO #{app_user};"
    execute "GRANT CREATE ON SCHEMA public TO #{app_user};"
  end

  def down
    app_user = ENV['<%= RlsMultiTenant.app_user_env_var %>']
    
    # Revoke permissions
    execute "REVOKE ALL ON SCHEMA public FROM #{app_user};"
    execute "REVOKE CONNECT ON DATABASE #{ActiveRecord::Base.connection.current_database} FROM #{app_user};"
    
    # Drop user
    execute "DROP ROLE IF EXISTS #{app_user};"
  end
end
