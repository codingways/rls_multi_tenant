# frozen_string_literal: true

module RlsMultiTenant
  class Railtie < Rails::Railtie
    # Load generators after Rails is fully initialized
    initializer "rls_multi_tenant.load_generators", after: :set_routes_reloader do |app|
      require "rls_multi_tenant/generators/install/install_generator"
      require "rls_multi_tenant/generators/setup/setup_generator"
      require "rls_multi_tenant/generators/migration/migration_generator"
      require "rls_multi_tenant/generators/model/model_generator"
      require "rls_multi_tenant/generators/task/task_generator"
    end

    initializer "rls_multi_tenant.configure" do |app|
      # Configure the gem
      RlsMultiTenant.configure do |config|
        config.tenant_class_name = "Tenant"
        config.tenant_id_column = :tenant_id
        config.app_user_env_var = "POSTGRES_APP_USER"
        config.enable_security_validation = true
      end
    end

    initializer "rls_multi_tenant.security_validation", after: :load_config_initializers do |app|
      if RlsMultiTenant.enable_security_validation
        app.config.after_initialize do
          begin
            RlsMultiTenant::SecurityValidator.validate_environment!
            RlsMultiTenant::SecurityValidator.validate_database_user!
          rescue => e
            Rails.logger.error "RLS Multi-tenant initialization failed: #{e.message}"
            raise e
          end
        end
      end
    end
  end
end
