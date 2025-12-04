# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant::Concerns::TenantContext do
  describe 'module structure' do
    it 'is a module' do
      expect(described_class).to be_a(Module)
    end

    it 'extends ActiveSupport::Concern' do
      expect(described_class.ancestors).to include(ActiveSupport::Concern)
    end
  end

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

  describe 'nested switch functionality' do
    let(:tenant1_id) { 'tenant-1' }
    let(:tenant2_id) { 'tenant-2' }
    let(:tenant_session_var) { 'rls.tenant_id' }
    let(:current_tenant_id) { nil }

    let(:test_class) do
      Class.new do
        include RlsMultiTenant::Concerns::TenantContext

        class << self
          attr_reader :connection
        end

        class << self
          attr_writer :connection
        end
      end
    end

    before do
      stub_const('Tenant', Class.new do
        def initialize(id)
          @id = id
        end

        attr_reader :id

        def self.exists?(*)
          true
        end

        def self.find_by(id:)
          return nil if id.blank?

          new(id)
        end
      end)

      allow(RlsMultiTenant).to receive_messages(
        tenant_class: Tenant,
        tenant_class_name: 'Tenant',
        tenant_id_column: :tenant_id
      )

      # rubocop:disable RSpec/VerifiedDoubles
      mock_connection = double('Connection')
      # rubocop:enable RSpec/VerifiedDoubles
      allow(mock_connection).to receive(:active?).and_return(true)

      tenant_state = { current: nil }

      allow(mock_connection).to receive(:execute) do |sql|
        if sql.include?('current_setting')
          [{ 'tenant_id' => tenant_state[:current] }]
        elsif sql.start_with?('SET')
          tenant_id_match = sql.match(/SET #{Regexp.escape(tenant_session_var)} = '(.+)'/)
          tenant_state[:current] = tenant_id_match[1] if tenant_id_match
        elsif sql.start_with?('RESET')
          tenant_state[:current] = nil
        end
      end

      allow(mock_connection).to receive(:quote) do |value|
        "'#{value}'"
      end

      test_class.connection = mock_connection
    end

    it 'handles nested switches correctly' do
      tenant1_instance = Tenant.new(tenant1_id)
      tenant2_instance = Tenant.new(tenant2_id)

      test_class.switch(tenant1_instance) do
        expect(test_class.current.id).to eq(tenant1_id)

        test_class.switch(tenant2_instance) do
          expect(test_class.current.id).to eq(tenant2_id)
        end

        expect(test_class.current.id).to eq(tenant1_id)
      end

      expect(test_class.current).to be_nil
    end
  end
end
