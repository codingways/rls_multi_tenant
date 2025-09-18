# frozen_string_literal: true

module RlsMultiTenant
  class SecurityValidator
    class << self
      def validate_database_user!
        return unless RlsMultiTenant.enable_security_validation

        begin
          # Get the current database configuration
          db_config = ActiveRecord::Base.connection_db_config
          username = db_config.configuration_hash[:username]

          # Check if the user has bypassrls privilege
          bypassrls_check = ActiveRecord::Base.connection.execute(
            "SELECT rolbypassrls FROM pg_roles WHERE rolname = '#{username}'"
          ).first

          if bypassrls_check && bypassrls_check['rolbypassrls']
            raise SecurityError, "Database user '#{username}' has BYPASSRLS privilege. " \
                                 'In order to use RLS Multi-tenant, you must use a non-privileged user ' \
                                 'without BYPASSRLS privilege.'
          end

          # Log the security check result
          Rails.logger&.info "✅ RLS Multi-tenant security check passed: Using user '#{username}' without BYPASSRLS privilege"
        rescue StandardError => e
          Rails.logger&.error "❌ RLS Multi-tenant security check failed: #{e.message}"
          raise e
        end
      end
    end
  end
end
