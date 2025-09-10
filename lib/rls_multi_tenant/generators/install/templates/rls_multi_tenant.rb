# frozen_string_literal: true

RlsMultiTenant.configure do |config|
  # Configure the tenant model class name
  config.tenant_class_name = "Tenant"
  
  # Configure the tenant ID column name
  config.tenant_id_column = :tenant_id
  
  # Configure the environment variable for the app user
  config.app_user_env_var = "POSTGRES_APP_USER"
  
  # Enable/disable security validation
  config.enable_security_validation = true
end
