# frozen_string_literal: true

RlsMultiTenant.configure do |config|
  # Configure the tenant model class name
  config.tenant_class_name = 'Tenant'

  # Configure the tenant ID column name
  config.tenant_id_column = :tenant_id

  # Enable/disable security validation
  config.enable_security_validation = true

  # Enable/disable subdomain-based tenant switching middleware
  config.enable_subdomain_middleware = true

  # Configure the field to use for subdomain matching (default: :subdomain)
  # This should be a field on your tenant model that contains the subdomain
  config.subdomain_field = :subdomain
end
