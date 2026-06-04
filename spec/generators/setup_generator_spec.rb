# frozen_string_literal: true

require 'rails_helper'
require 'rls_multi_tenant/generators/setup/setup_generator'

RSpec.describe RlsMultiTenant::Generators::SetupGenerator, type: :generator do
  destination File.expand_path('../tmp/generators', __dir__)

  before do
    prepare_destination
    run_generator
  end

  it 'creates the tenant model wired through TenantContext' do
    assert_file 'app/models/tenant.rb',
                /class Tenant < ApplicationRecord/,
                /include RlsMultiTenant::Concerns::TenantContext/
  end

  it 'creates the uuid extension migration' do
    assert_migration 'db/migrate/enable_uuid_extension.rb'
  end

  it 'creates the tenants migration' do
    assert_migration 'db/migrate/create_tenants.rb' do |migration|
      assert_match(/create_table :tenants/, migration)
    end
  end
end
