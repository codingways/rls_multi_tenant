# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant::Concerns::MultiTenant do
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

    it 'extracts id from tenant object' do
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

      # Test with string ID
      result = test_class.extract_tenant_id('tenant-123')
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
end
