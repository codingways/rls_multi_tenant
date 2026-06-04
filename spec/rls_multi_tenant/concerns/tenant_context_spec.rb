# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant::Concerns::TenantContext do
  describe 'extract_tenant_id method' do
    let(:test_class) do
      Class.new do
        include RlsMultiTenant::Concerns::TenantContext
      end
    end

    before do
      stub_const('Tenant', Class.new do
        def initialize(id)
          @id = id
        end

        attr_reader :id
      end)

      allow(RlsMultiTenant).to receive_messages(
        tenant_class: Tenant,
        tenant_class_name: 'Tenant'
      )
    end

    it 'extracts id from tenant object using is_a? check' do
      tenant_instance = Tenant.new('tenant-123')
      result = test_class.send(:extract_tenant_id, tenant_instance)
      expect(result).to eq('tenant-123')
    end

    it 'returns string id as is' do
      result = test_class.send(:extract_tenant_id, 'tenant-456')
      expect(result).to eq('tenant-456')
    end

    it 'returns integer id as is' do
      result = test_class.send(:extract_tenant_id, 789)
      expect(result).to eq(789)
    end

    it 'raises error for invalid input' do
      expect do
        test_class.send(:extract_tenant_id, Object.new)
      end.to raise_error(ArgumentError, /Expected Tenant object or tenant_id/)
    end

    it 'returns nil for nil (resolves to a clean reset)' do
      expect(test_class.send(:extract_tenant_id, nil)).to be_nil
    end
  end

  describe '.tenant_session_var' do
    let(:test_class) do
      Class.new do
        include RlsMultiTenant::Concerns::TenantContext
      end
    end

    it 'builds the GUC name from the configured column' do
      allow(RlsMultiTenant).to receive(:tenant_id_column).and_return(:tenant_id)
      expect(test_class.tenant_session_var).to eq('rls.tenant_id')
    end

    it 'raises ConfigurationError for an unsafe column name' do
      allow(RlsMultiTenant).to receive(:tenant_id_column).and_return('id); DROP TABLE x; --')
      expect { test_class.tenant_session_var }.to raise_error(RlsMultiTenant::ConfigurationError)
    end
  end

  describe 'tenant validation' do
    let(:tenant_id) { 'valid-tenant-id' }
    let(:invalid_tenant_id) { 'invalid-tenant-id' }

    let(:test_class) do
      Class.new do
        include RlsMultiTenant::Concerns::TenantContext
      end
    end

    before do
      stub_const('Tenant', Class.new do
        def self.exists?(id:)
          id == 'valid-tenant-id'
        end
      end)

      allow(RlsMultiTenant).to receive_messages(
        tenant_class: Tenant,
        tenant_class_name: 'Tenant'
      )
    end

    describe 'validate_tenant_exists!' do
      it 'does not raise error for existing tenant' do
        expect { test_class.send(:validate_tenant_exists!, tenant_id) }.not_to raise_error
      end

      it 'raises StandardError for non-existing tenant' do
        expect do
          test_class.send(:validate_tenant_exists!, invalid_tenant_id)
        end.to raise_error(StandardError, /Tenant with id 'invalid-tenant-id' not found/)
      end

      it 'does not raise error for blank tenant_id' do
        expect { test_class.send(:validate_tenant_exists!, nil) }.not_to raise_error
        expect { test_class.send(:validate_tenant_exists!, '') }.not_to raise_error
      end
    end
  end
end
