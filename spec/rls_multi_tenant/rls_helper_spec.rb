# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RlsMultiTenant::RlsHelper do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }

  before do
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    allow(connection).to receive(:execute).and_return([])
    allow(connection).to receive(:quote_table_name) { |name| %("#{name}") }
    allow(connection).to receive(:quote_column_name) { |name| %("#{name}") }
    allow(connection).to receive(:quote) { |value| "'#{value}'" }
  end

  describe '.enable_rls_for_table' do
    it 'quotes the table, column and policy identifiers' do
      described_class.enable_rls_for_table('posts')

      expect(connection).to have_received(:execute)
        .with(a_string_matching(/ALTER TABLE "posts" ENABLE ROW LEVEL SECURITY/))
      expect(connection).to have_received(:execute)
        .with(a_string_matching(/CREATE POLICY "posts_app_user" ON "posts"/))
    end

    it 'passes the GUC name as a quoted literal' do
      described_class.enable_rls_for_table('posts')

      expect(connection).to have_received(:execute)
        .with(a_string_matching(/current_setting\('rls\.tenant_id', TRUE\)/))
    end

    it 'rejects an injection attempt in the table name' do
      expect { described_class.enable_rls_for_table('posts; DROP TABLE users') }
        .to raise_error(ArgumentError, /Invalid SQL identifier/)
    end

    it 'rejects an injection attempt in the tenant column' do
      expect { described_class.enable_rls_for_table('posts', tenant_column: 'x = 1) OR (1=1') }
        .to raise_error(ArgumentError, /Invalid SQL identifier/)
    end
  end

  describe '.disable_rls_for_table' do
    it 'rejects an injection attempt in the table name' do
      expect { described_class.disable_rls_for_table('posts"; DROP') }
        .to raise_error(ArgumentError, /Invalid SQL identifier/)
    end
  end

  describe '.rls_enabled?' do
    it 'passes the table name as a quoted literal, not interpolated' do
      allow(connection).to receive(:execute).and_return(
        [{ 'relrowsecurity' => true, 'relforcerowsecurity' => true }]
      )

      expect(described_class.rls_enabled?('posts')).to be(true)
      expect(connection).to have_received(:execute).with(a_string_matching(/relname = 'posts'/))
    end
  end
end
