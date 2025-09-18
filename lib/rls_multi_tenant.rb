# frozen_string_literal: true

require 'rls_multi_tenant/version'
require 'rls_multi_tenant/concerns/multi_tenant'
require 'rls_multi_tenant/concerns/tenant_context'
require 'rls_multi_tenant/security_validator'
require 'rls_multi_tenant/rls_helper'
require 'rls_multi_tenant/middleware/subdomain_tenant_selector'
require 'rls_multi_tenant/generators/shared/template_helper'
require 'rls_multi_tenant/railtie' if defined?(Rails)

module RlsMultiTenant
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class SecurityError < Error; end

  # Configuration options
  class << self
    attr_writer :tenant_class_name, :tenant_id_column, :enable_security_validation, :enable_subdomain_middleware,
                :subdomain_field

    def configure
      yield self
    end

    def tenant_class_name
      @tenant_class_name ||= 'Tenant'
    end

    def tenant_class
      @tenant_class ||= tenant_class_name.constantize
    end

    def tenant_id_column
      @tenant_id_column ||= :tenant_id
    end

    def enable_security_validation
      @enable_security_validation.nil? || @enable_security_validation
    end

    def enable_subdomain_middleware
      @enable_subdomain_middleware.nil? ? false : @enable_subdomain_middleware
    end

    def subdomain_field
      @subdomain_field ||= :subdomain
    end
  end

  # Default configuration
  self.tenant_class_name = 'Tenant'
  self.tenant_id_column = :tenant_id
  self.enable_security_validation = true
  self.enable_subdomain_middleware = true
  self.subdomain_field = :subdomain
end
