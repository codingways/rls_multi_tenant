# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RLS Multi-Tenant Basic Tests' do
  describe 'RlsMultiTenant module' do
    it 'has correct default configuration' do
      expect(RlsMultiTenant.tenant_class_name).to eq('Tenant')
      expect(RlsMultiTenant.tenant_id_column).to eq(:tenant_id)
      expect(RlsMultiTenant.app_user_env_var).to eq('POSTGRES_APP_USER')
      expect(RlsMultiTenant.enable_security_validation).to be true
    end

    it 'allows configuration changes' do
      original_name = RlsMultiTenant.tenant_class_name
      
      RlsMultiTenant.tenant_class_name = 'Organization'
      expect(RlsMultiTenant.tenant_class_name).to eq('Organization')
      
      # Reset
      RlsMultiTenant.tenant_class_name = original_name
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

    it 'has validate_environment! method' do
      expect(RlsMultiTenant::SecurityValidator).to respond_to(:validate_environment!)
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
      app = double('app')
      middleware = RlsMultiTenant::Middleware::SubdomainTenantSelector.new(app)
      expect(middleware).to be_a(RlsMultiTenant::Middleware::SubdomainTenantSelector)
    end
  end
end
