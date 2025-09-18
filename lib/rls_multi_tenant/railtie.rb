# frozen_string_literal: true

module RlsMultiTenant
  class Railtie < Rails::Railtie
    # Load generators after Rails is fully initialized
    initializer 'rls_multi_tenant.load_generators', after: :set_routes_reloader do |_app|
      require 'rls_multi_tenant/generators/install/install_generator'
      require 'rls_multi_tenant/generators/setup/setup_generator'
      require 'rls_multi_tenant/generators/migration/migration_generator'
      require 'rls_multi_tenant/generators/model/model_generator'
    end

    initializer 'rls_multi_tenant.configure' do |_app|
      # Configure the gem
      RlsMultiTenant.configure do |config|
        config.tenant_class_name = 'Tenant'
        config.tenant_id_column = :tenant_id
        config.enable_security_validation = true
      end
    end

    initializer 'rls_multi_tenant.security_validation', after: :load_config_initializers do |app|
      if RlsMultiTenant.enable_security_validation
        app.config.after_initialize do
          RlsMultiTenant::SecurityValidator.validate_database_user!
        rescue StandardError => e
          Rails.logger.error "RLS Multi-tenant initialization failed: #{e.message}"
          raise e
        end
      end
    end

    initializer 'rls_multi_tenant.middleware', after: :load_config_initializers do |app|
      if RlsMultiTenant.enable_subdomain_middleware
        app.config.middleware.use RlsMultiTenant::Middleware::SubdomainTenantSelector
      end
    end
  end
end
