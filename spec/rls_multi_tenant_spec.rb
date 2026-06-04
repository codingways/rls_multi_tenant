# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant do
  describe 'default configuration' do
    it 'defaults the tenant class and id column' do
      expect(described_class.tenant_class_name).to eq('Tenant')
      expect(described_class.tenant_id_column).to eq(:tenant_id)
    end

    it 'defaults the subdomain settings' do
      expect(described_class.subdomain_field).to eq(:subdomain)
      expect(described_class.excluded_subdomains).to eq(['www'])
    end

    it 'enables security validation and the subdomain middleware by default' do
      expect(described_class.enable_security_validation).to be(true)
      expect(described_class.enable_subdomain_middleware).to be(true)
    end
  end

  describe '.tenant_class' do
    # Config is snapshotted/restored globally (see spec/support/configuration.rb).
    it 'resolves the configured class name on every call (not memoized)' do
      stub_const('Organization', Class.new)
      described_class.tenant_class_name = 'Organization'
      expect(described_class.tenant_class).to eq(Organization)

      stub_const('Account', Class.new)
      described_class.tenant_class_name = 'Account'
      expect(described_class.tenant_class).to eq(Account)
    end
  end
end
