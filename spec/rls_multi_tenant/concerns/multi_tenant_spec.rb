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

  describe '#set_tenant_id' do
    let(:mock_active_record) do
      Class.new do
        def self.belongs_to(*); end
        def self.validates(*); end
        def self.before_validation(*); end
        def self.name = 'Widget'

        attr_accessor :tenant_id
      end
    end

    let(:model_class) do
      Class.new(mock_active_record) do
        include RlsMultiTenant::Concerns::MultiTenant
      end
    end

    let(:instance) { model_class.new }
    let(:current_tenant) { double('tenant', id: 'tenant-1') } # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(RlsMultiTenant).to receive_messages(tenant_id_column: :tenant_id, tenant_class: tenant_class)
    end

    context 'without a tenant context' do
      let(:tenant_class) { double('Tenant', current: nil) } # rubocop:disable RSpec/VerifiedDoubles

      it 'raises an error' do
        expect { instance.send(:set_tenant_id) }
          .to raise_error(RlsMultiTenant::Error, /without tenant context/)
      end
    end

    context 'with a tenant context' do
      let(:tenant_class) { double('Tenant', current: current_tenant) } # rubocop:disable RSpec/VerifiedDoubles

      it 'assigns the current tenant id when blank' do
        instance.tenant_id = nil
        instance.send(:set_tenant_id)
        expect(instance.tenant_id).to eq('tenant-1')
      end

      it 'keeps a matching explicit tenant id' do
        instance.tenant_id = 'tenant-1'
        expect { instance.send(:set_tenant_id) }.not_to raise_error
        expect(instance.tenant_id).to eq('tenant-1')
      end

      it 'rejects a tenant id for a different tenant' do
        instance.tenant_id = 'tenant-2'
        expect { instance.send(:set_tenant_id) }
          .to raise_error(RlsMultiTenant::Error, /different tenant/)
      end
    end
  end
end
