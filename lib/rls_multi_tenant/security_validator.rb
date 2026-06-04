# frozen_string_literal: true

module RlsMultiTenant
  class SecurityValidator
    class << self
      def validate_database_user!
        return unless RlsMultiTenant.enable_security_validation

        begin
          # Inspect the actual connected role (current_user), not the configured
          # username, so the check reflects what PostgreSQL really enforces and
          # avoids interpolating a config value into SQL.
          role = ActiveRecord::Base.connection.execute(<<~SQL).first
            SELECT current_user AS username,
                   rolsuper,
                   rolbypassrls
            FROM pg_roles
            WHERE rolname = current_user
          SQL

          username = role && role['username']

          # A SUPERUSER bypasses RLS unconditionally, regardless of the
          # rolbypassrls flag, so it must be rejected explicitly.
          if truthy?(role && role['rolsuper'])
            raise SecurityError, "Database user '#{username}' is a SUPERUSER. " \
                                 'Superusers bypass Row Level Security entirely. You must use a ' \
                                 'non-privileged, non-superuser role for RLS Multi-tenant.'
          end

          # BYPASSRLS can also be inherited through role membership, so check the
          # effective privilege across every role the user is a member of.
          if bypassrls_effective?
            raise SecurityError, "Database user '#{username}' has BYPASSRLS privilege " \
                                 '(directly or through an inherited role). ' \
                                 'In order to use RLS Multi-tenant, you must use a non-privileged user ' \
                                 'without BYPASSRLS privilege.'
          end

          Rails.logger&.info "✅ RLS Multi-tenant security check passed: Using user '#{username}' " \
                             'without SUPERUSER or BYPASSRLS privileges'
        rescue StandardError => e
          Rails.logger&.error "❌ RLS Multi-tenant security check failed: #{e.message}"
          raise e
        end
      end

      private

      def bypassrls_effective?
        result = ActiveRecord::Base.connection.execute(<<~SQL).first
          SELECT bool_or(rolbypassrls) AS bypass
          FROM pg_roles
          WHERE pg_has_role(current_user, oid, 'USAGE')
        SQL

        truthy?(result && result['bypass'])
      end

      # PostgreSQL boolean columns may come back as true/false or 't'/'f'
      # depending on the adapter/decoder configuration.
      def truthy?(value)
        value == true || value == 't'
      end
    end
  end
end
