# frozen_string_literal: true

require "rls_multi_tenant/version"
require "rls_multi_tenant/concerns/multi_tenant"
require "rls_multi_tenant/concerns/tenant_context"
require "rls_multi_tenant/security_validator"
require "rls_multi_tenant/rls_helper"
require "rls_multi_tenant/generators/shared/template_helper"
require "rls_multi_tenant/railtie" if defined?(Rails)

module RlsMultiTenant
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class SecurityError < Error; end

  # Configuration options
  class << self
    attr_accessor :tenant_class_name, :tenant_id_column, :app_user_env_var, :enable_security_validation

    def configure
      yield self
    end

    def tenant_class
      @tenant_class ||= tenant_class_name.constantize
    end

    def tenant_id_column
      @tenant_id_column ||= :tenant_id
    end

    def app_user_env_var
      @app_user_env_var ||= "POSTGRES_APP_USER"
    end

    def enable_security_validation
      @enable_security_validation.nil? ? true : @enable_security_validation
    end
  end

  # Default configuration
  self.tenant_class_name = "Tenant"
  self.tenant_id_column = :tenant_id
  self.app_user_env_var = "POSTGRES_APP_USER"
  self.enable_security_validation = true
end
