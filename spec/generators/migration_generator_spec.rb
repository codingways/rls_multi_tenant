# frozen_string_literal: true

require 'rails_helper'
require 'rls_multi_tenant/generators/migration/migration_generator'

RSpec.describe RlsMultiTenant::Generators::MigrationGenerator, type: :generator do
  destination File.expand_path('../tmp/generators', __dir__)

  before { prepare_destination }

  describe 'create_tenant' do
    before { run_generator(%w[create_tenant]) }

    it 'creates the tenants migration' do
      assert_migration 'db/migrate/create_tenants.rb' do |migration|
        assert_match(/create_table :tenants/, migration)
      end
    end
  end

  describe 'enable_uuid' do
    before { run_generator(%w[enable_uuid]) }

    it 'creates the uuid extension migration' do
      assert_migration 'db/migrate/enable_uuid_extension.rb'
    end
  end

  describe 'enable_rls' do
    before do
      # The generator prompts for the table name; supply it without stdin.
      allow_any_instance_of(described_class).to receive(:table_name).and_return('posts') # rubocop:disable RSpec/AnyInstance
      run_generator(%w[enable_rls])
    end

    it 'creates an enable-RLS migration for the given table' do
      assert_migration 'db/migrate/enable_rls_for_posts.rb' do |migration|
        assert_match(/ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY/, migration)
        assert_match(/CREATE POLICY posts_app_user ON posts/, migration)
      end
    end
  end
end
