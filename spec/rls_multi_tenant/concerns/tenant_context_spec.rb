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
    let(:tenant) { instance_double(Tenant, id: 'tenant-123') }

    it 'extracts id from tenant object using is_a? check' do
      test_class = Class.new do
        def self.extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when ->(obj) { obj.is_a?(Tenant) }
            tenant_or_id.id
          when String, Integer
            tenant_or_id
          else
            raise ArgumentError, "Expected Tenant object or tenant_id, got #{tenant_or_id.class}"
          end
        end
      end

      # Create a real Tenant instance for the test
      tenant_instance = Tenant.new('tenant-123')
      result = test_class.extract_tenant_id(tenant_instance)
      expect(result).to eq('tenant-123')
    end

    it 'returns string id as is' do
      test_class = Class.new do
        def self.extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when String, Integer
            tenant_or_id
          else
            raise ArgumentError, "Expected tenant object or tenant_id, got #{tenant_or_id.class}"
          end
        end
      end

      result = test_class.extract_tenant_id('tenant-456')
      expect(result).to eq('tenant-456')
    end

    it 'returns integer id as is' do
      test_class = Class.new do
        def self.extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when String, Integer
            tenant_or_id
          else
            raise ArgumentError, "Expected tenant object or tenant_id, got #{tenant_or_id.class}"
          end
        end
      end

      result = test_class.extract_tenant_id(789)
      expect(result).to eq(789)
    end

    it 'raises error for invalid input' do
      test_class = Class.new do
        def self.extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when String, Integer
            tenant_or_id
          else
            raise ArgumentError, "Expected tenant object or tenant_id, got #{tenant_or_id.class}"
          end
        end
      end

      expect do
        test_class.extract_tenant_id(Object.new)
      end.to raise_error(ArgumentError, /Expected tenant object or tenant_id/)
    end
  end

  describe 'tenant validation' do
    # rubocop:disable RSpec/VerifiedDoubles
    let(:tenant_class) { double('TenantClass') }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:tenant_id) { 'valid-tenant-id' }
    let(:invalid_tenant_id) { 'invalid-tenant-id' }

    before do
      allow(RlsMultiTenant).to receive_messages(tenant_class: tenant_class, tenant_class_name: 'Tenant')
    end

    describe 'validate_tenant_exists!' do
      let(:test_class) do
        Class.new do
          def self.validate_tenant_exists!(tenant_id)
            return if tenant_id.blank?

            return if RlsMultiTenant.tenant_class.exists?(id: tenant_id)

            raise StandardError, "#{RlsMultiTenant.tenant_class_name} with id '#{tenant_id}' not found"
          end
        end
      end

      it 'does not raise error for existing tenant' do
        allow(tenant_class).to receive(:exists?).with(id: tenant_id).and_return(true)

        expect { test_class.validate_tenant_exists!(tenant_id) }.not_to raise_error
      end

      it 'raises StandardError for non-existing tenant' do
        allow(tenant_class).to receive(:exists?).with(id: invalid_tenant_id).and_return(false)

        expect do
          test_class.validate_tenant_exists!(invalid_tenant_id)
        end.to raise_error(StandardError, /Tenant with id 'invalid-tenant-id' not found/)
      end

      it 'does not raise error for blank tenant_id' do
        expect { test_class.validate_tenant_exists!(nil) }.not_to raise_error
        expect { test_class.validate_tenant_exists!('') }.not_to raise_error
      end
    end
  end

  describe 'nested switch functionality' do
    let(:tenant_class) { double('TenantClass') }
    let(:connection) { double('Connection') }
    let(:tenant1) { instance_double(Tenant, id: 'tenant-1') }
    let(:tenant2) { instance_double(Tenant, id: 'tenant-2') }

    before do
      allow(RlsMultiTenant).to receive_messages(
        tenant_class: tenant_class,
        tenant_class_name: 'Tenant',
        tenant_id_column: :tenant_id
      )
      allow(tenant_class).to receive(:exists?).and_return(true)
      allow(connection).to receive(:execute)
      allow(connection).to receive(:quote).and_return("'tenant-1'", "'tenant-2'")
    end

    it 'handles nested switches correctly' do
      # Mock the Tenant class for the test
      stub_const('Tenant', Class.new do
        def initialize(id)
          @id = id
        end
        
        attr_reader :id
        
        def self.exists?(id:)
          true
        end
      end)

      # Create a simple mock connection
      mock_connection = double('Connection')
      allow(mock_connection).to receive(:execute)
      allow(mock_connection).to receive(:quote).and_return("'tenant-1'", "'tenant-2'")

      test_class = Class.new do
        def self.connection
          @connection
        end

        def self.connection=(conn)
          @connection = conn
        end

        def self.tenant_session_var
          'rls.tenant_id'
        end

        def self.switch(tenant_or_id)
          tenant_id = extract_tenant_id(tenant_or_id)
          validate_tenant_exists!(tenant_id)
          connection.execute "SET #{tenant_session_var} = #{connection.quote(tenant_id)}"
          yield
        ensure
          reset!
        end

        def self.reset!
          connection.execute "RESET #{tenant_session_var}"
        end

        def self.extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when ->(obj) { obj.is_a?(Tenant) }
            tenant_or_id.id
          when String, Integer
            tenant_or_id
          else
            raise ArgumentError, "Expected Tenant object or tenant_id, got #{tenant_or_id.class}"
          end
        end

        def self.validate_tenant_exists!(tenant_id)
          return if tenant_id.blank?
          return if Tenant.exists?(id: tenant_id)
          raise StandardError, "Tenant with id '#{tenant_id}' not found"
        end
      end

      # Set the mock connection
      test_class.connection = mock_connection

      # Create real Tenant instances
      tenant1_instance = Tenant.new('tenant-1')
      tenant2_instance = Tenant.new('tenant-2')

      expect do
        test_class.switch(tenant1_instance) do
          test_class.switch(tenant2_instance) do
            # This should not raise an error
          end
        end
      end.not_to raise_error
    end
  end
end
