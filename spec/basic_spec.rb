# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RLS Multi-Tenant Basic Tests' do
  describe 'RlsMultiTenant module' do
    it 'has correct default tenant configuration' do
      expect(RlsMultiTenant.tenant_class_name).to eq('Tenant')
      expect(RlsMultiTenant.tenant_id_column).to eq(:tenant_id)
    end

    it 'has correct default security configuration' do
      expect(RlsMultiTenant.enable_security_validation).to be true
      expect(RlsMultiTenant.enable_subdomain_middleware).to be true
    end

    it 'has correct default subdomain configuration' do
      expect(RlsMultiTenant.subdomain_field).to eq(:subdomain)
      expect(RlsMultiTenant.excluded_subdomains).to eq(['www'])
    end

    it 'allows configuration changes' do
      original_name = RlsMultiTenant.tenant_class_name
      original_excluded = RlsMultiTenant.excluded_subdomains

      RlsMultiTenant.tenant_class_name = 'Organization'
      expect(RlsMultiTenant.tenant_class_name).to eq('Organization')

      RlsMultiTenant.excluded_subdomains = %w[www admin api]
      expect(RlsMultiTenant.excluded_subdomains).to eq(%w[www admin api])

      # Reset
      RlsMultiTenant.tenant_class_name = original_name
      RlsMultiTenant.excluded_subdomains = original_excluded
    end
  end

  describe 'Error classes' do
    it 'defines Error class' do
      expect(RlsMultiTenant::Error).to be < StandardError
    end

    it 'defines ConfigurationError class' do
      expect(RlsMultiTenant::ConfigurationError).to be < RlsMultiTenant::Error
    end

    it 'defines SecurityError class' do
      expect(RlsMultiTenant::SecurityError).to be < RlsMultiTenant::Error
    end
  end

  describe 'Concerns' do
    it 'MultiTenant concern is a module' do
      expect(RlsMultiTenant::Concerns::MultiTenant).to be_a(Module)
    end

    it 'TenantContext concern is a module' do
      expect(RlsMultiTenant::Concerns::TenantContext).to be_a(Module)
    end
  end

  describe 'Security Validator' do
    it 'has validate_database_user! method' do
      expect(RlsMultiTenant::SecurityValidator).to respond_to(:validate_database_user!)
    end
  end

  describe 'RLS Helper' do
    it 'has enable_rls_for_table method' do
      expect(RlsMultiTenant::RlsHelper).to respond_to(:enable_rls_for_table)
    end

    it 'has disable_rls_for_table method' do
      expect(RlsMultiTenant::RlsHelper).to respond_to(:disable_rls_for_table)
    end
  end

  describe 'Middleware' do
    it 'SubdomainTenantSelector is a class' do
      expect(RlsMultiTenant::Middleware::SubdomainTenantSelector).to be_a(Class)
    end

    it 'can be instantiated with an app' do
      app = instance_double(Rack::App)
      middleware = RlsMultiTenant::Middleware::SubdomainTenantSelector.new(app)
      expect(middleware).to be_a(RlsMultiTenant::Middleware::SubdomainTenantSelector)
    end

    it 'excludes configured subdomains from tenant lookup' do
      # Test that excluded_subdomains configuration is respected
      original_excluded = RlsMultiTenant.excluded_subdomains

      RlsMultiTenant.excluded_subdomains = %w[www admin]

      middleware = RlsMultiTenant::Middleware::SubdomainTenantSelector.new(instance_double(Rack::App))

      # Test excluded_subdomain? method via reflection
      excluded_method = middleware.send(:excluded_subdomain?, 'www')
      expect(excluded_method).to be true

      excluded_method = middleware.send(:excluded_subdomain?, 'admin')
      expect(excluded_method).to be true

      excluded_method = middleware.send(:excluded_subdomain?, 'tenant1')
      expect(excluded_method).to be false

      # Reset
      RlsMultiTenant.excluded_subdomains = original_excluded
    end
  end
end
