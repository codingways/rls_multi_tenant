# frozen_string_literal: true

module RlsMultiTenant
  class SecurityValidator
    class << self
      def validate_database_user!
        return unless RlsMultiTenant.enable_security_validation
        return if skip_validation?

        begin
          # Get the current database configuration
          db_config = ActiveRecord::Base.connection_db_config
          username = db_config.configuration_hash[:username]

          # Check if the current user has SUPERUSER privileges
          superuser_check = ActiveRecord::Base.connection.execute(
            "SELECT rolname, rolsuper FROM pg_roles WHERE rolname = current_user"
          ).first

          if superuser_check && superuser_check['rolsuper']
            raise SecurityError, "Database user '#{username}' has SUPERUSER privileges. " \
                                "In order to use RLS Multi-tenant, you must use a non-privileged user without SUPERUSER rights." \
                                "Did you remember to edit database.yml in order to use the POSTGRES_APP_USER and POSTGRES_APP_PASSWORD?"
          end

          # Log the security check result
          Rails.logger&.info "✅ RLS Multi-tenant security check passed: Using user '#{username}' without SUPERUSER privileges"

        rescue => e
          Rails.logger&.error "❌ RLS Multi-tenant security check failed: #{e.message}"
          raise e
        end
      end

      def validate_environment!
        return if skip_validation?
        return unless RlsMultiTenant.enable_security_validation
        
        app_user = ENV[RlsMultiTenant.app_user_env_var]
        
        if app_user.blank?
          raise ConfigurationError, "#{RlsMultiTenant.app_user_env_var} environment variable must be set"
        elsif ["postgres", "root"].include?(app_user)
          raise SecurityError, "Cannot use privileged PostgreSQL user '#{app_user}'. " \
                              "In order to use RLS Multi-tenant, you must use a non-privileged user without SUPERUSER rights." \
                              "Did you remember to edit database.yml in order to use the POSTGRES_APP_USER and POSTGRES_APP_PASSWORD?"
        end
      end

      private

      def skip_validation?
        # Skip validation if we're running an install or setup generator
        return true if ARGV.any? { |arg| arg.include?('rls_multi_tenant:install') || arg.include?('rls_multi_tenant:setup') }
        
        # Skip validation if we're in admin mode (set by db_as:admin task)
        return true if ENV['RLS_MULTI_TENANT_ADMIN_MODE'] == 'true'
        
        false
      end
    end
  end
end
