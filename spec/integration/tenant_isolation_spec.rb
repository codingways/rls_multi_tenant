# frozen_string_literal: true

require 'rails_helper'

# These specs run against a real PostgreSQL database (see spec/support/db.rb).
# They exercise the actual RLS policy and the gem's tenant switching end to end,
# which is the only way to verify the core isolation guarantee.
RSpec.describe 'RLS tenant isolation', :integration do
  let(:tenant_a) { IntegrationDB.seed_tenant!(name: 'Acme', subdomain: 'acme') }
  let(:tenant_b) { IntegrationDB.seed_tenant!(name: 'Globex', subdomain: 'globex') }

  before do
    IntegrationDB.seed_post!(tenant_id: tenant_a, title: 'a-1')
    IntegrationDB.seed_post!(tenant_id: tenant_a, title: 'a-2')
    IntegrationDB.seed_post!(tenant_id: tenant_b, title: 'b-1')
  end

  describe 'without a tenant context' do
    it 'returns no rows (fails closed)' do
      expect(Post.count).to eq(0)
    end

    it 'reports no current tenant' do
      expect(Tenant.current).to be_nil
    end
  end

  describe 'within a tenant context' do
    it 'only sees its own tenant rows' do
      Tenant.switch(tenant_a) do
        expect(Post.count).to eq(2)
        expect(Post.distinct.pluck(:tenant_id)).to eq([tenant_a])
      end

      Tenant.switch(tenant_b) do
        expect(Post.count).to eq(1)
        expect(Post.pluck(:title)).to eq(['b-1'])
      end
    end

    it 'reports the current tenant' do
      Tenant.switch(tenant_a) do
        expect(Tenant.current.id).to eq(tenant_a)
      end
    end
  end

  describe 'writing rows' do
    it 'auto-assigns the tenant_id from context on insert' do
      Tenant.switch(tenant_a) do
        post = Post.create!(title: 'fresh')
        expect(post.tenant_id).to eq(tenant_a)
      end

      Tenant.switch(tenant_a) { expect(Post.count).to eq(3) }
      Tenant.switch(tenant_b) { expect(Post.count).to eq(1) }
    end

    it 'rejects assigning a row to another tenant at the application layer' do
      Tenant.switch(tenant_a) do
        expect { Post.create!(title: 'x', tenant_id: tenant_b) }
          .to raise_error(RlsMultiTenant::Error, /different tenant/)
      end
    end

    it 'rejects an out-of-context insert at the database layer (WITH CHECK)' do
      Tenant.switch(tenant_a) do
        expect do
          ActiveRecord::Base.connection.execute(
            "INSERT INTO posts (tenant_id, title) VALUES ('#{tenant_b}', 'sneaky')"
          )
        end.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end

  describe 'switching by a unique field (Apartment-style)' do
    it 'switches by subdomain (the default field)' do
      Tenant.switch_by('acme') do
        expect(Tenant.current.id).to eq(tenant_a)
        expect(Post.count).to eq(2)
      end

      Tenant.switch_by('globex') do
        expect(Post.count).to eq(1)
      end
    end

    it 'switches by an explicit attribute' do
      Tenant.switch_by('Globex', attribute: :name) do
        expect(Tenant.current.id).to eq(tenant_b)
        expect(Post.count).to eq(1)
      end
    end

    it 'raises when no tenant matches' do
      expect { Tenant.switch_by('does-not-exist') { nil } }
        .to raise_error(RlsMultiTenant::Error, /not found/)
    end

    it 'supports the permanent switch_by! until reset' do
      Tenant.switch_by!('acme')
      expect(Tenant.current.id).to eq(tenant_a)
      expect(Post.count).to eq(2)
    ensure
      Tenant.reset!
    end
  end

  describe 'context lifecycle' do
    it 'restores the previous tenant after a nested switch' do
      Tenant.switch(tenant_a) do
        expect(Post.count).to eq(2)

        Tenant.switch(tenant_b) do
          expect(Post.count).to eq(1)
        end

        expect(Post.count).to eq(2)
      end
    end

    it 'clears the context when the block raises' do
      expect { Tenant.switch(tenant_a) { raise 'boom' } }.to raise_error('boom')

      expect(Tenant.current).to be_nil
      expect(Post.count).to eq(0)
    end

    it 'does not leak context after the block returns' do
      Tenant.switch(tenant_a) { Post.count }

      expect(Tenant.current).to be_nil
      expect(Post.count).to eq(0)
    end
  end
end
