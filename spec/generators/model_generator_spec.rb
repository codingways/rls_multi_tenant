# frozen_string_literal: true

require 'rails_helper'
require 'rls_multi_tenant/generators/model/model_generator'

RSpec.describe RlsMultiTenant::Generators::ModelGenerator, type: :generator do
  destination File.expand_path('../tmp/generators', __dir__)

  before do
    prepare_destination
    run_generator(%w[widget title:string published:boolean])
  end

  it 'generates the model with the MultiTenant concern' do
    assert_file 'app/models/widget.rb', /class Widget < ApplicationRecord/,
                /include RlsMultiTenant::Concerns::MultiTenant/
  end

  it 'generates a migration that creates the table with a tenant reference' do
    assert_migration 'db/migrate/create_widgets.rb' do |migration|
      assert_match(/create_table :widgets/, migration)
      assert_match(/t\.references :tenant.*type: :uuid/, migration)
      assert_match(/t\.string :title/, migration)
      assert_match(/t\.boolean :published/, migration)
    end
  end

  it 'generates a migration that enables and forces RLS with a policy' do
    assert_migration 'db/migrate/create_widgets.rb' do |migration|
      assert_match(/ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY/, migration)
      assert_match(/CREATE POLICY widgets_app_user ON widgets/, migration)
      assert_match(/DROP POLICY widgets_app_user ON widgets/, migration)
    end
  end
end
