# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Model Generator Tests' do
  describe 'Model template content' do
    let(:model_template_path) { File.join(__dir__, '../../lib/rls_multi_tenant/generators/model/templates/model.rb') }
    let(:migration_template_path) { File.join(__dir__, '../../lib/rls_multi_tenant/generators/model/templates/migration.rb') }
    
    it 'model template file exists' do
      expect(File.exist?(model_template_path)).to be true
    end

    it 'migration template file exists' do
      expect(File.exist?(migration_template_path)).to be true
    end

    it 'model template includes MultiTenant concern' do
      template_content = File.read(model_template_path)
      expect(template_content).to include('include RlsMultiTenant::Concerns::MultiTenant')
    end

    it 'model template has proper class structure' do
      template_content = File.read(model_template_path)
      expect(template_content).to include('class <%= model_name %> < ApplicationRecord')
    end

    it 'migration template creates table' do
      template_content = File.read(migration_template_path)
      expect(template_content).to include('create_table :<%= table_name %>')
    end

    it 'migration template includes tenant_id column' do
      template_content = File.read(migration_template_path)
      expect(template_content).to include('t.references :<%= tenant_id_column.to_s.gsub(\'_id\', \'\') %>')
    end

    it 'migration template includes foreign key constraint' do
      template_content = File.read(migration_template_path)
      expect(template_content).to include('foreign_key: { to_table: :<%= tenant_class_name.underscore.pluralize %> }')
    end

    it 'migration template includes RLS policy' do
      template_content = File.read(migration_template_path)
      expect(template_content).to include('CREATE POLICY <%= table_name %>_app_user ON <%= table_name %>')
    end

    it 'migration template includes specified attributes' do
      template_content = File.read(migration_template_path)
      expect(template_content).to include('<% @attributes.each do |attribute| -%>')
      expect(template_content).to include('t.<%= attribute[:type] %> :<%= attribute[:name] %>')
    end
  end

  describe 'Model generator class' do
    it 'generator file exists' do
      generator_path = File.join(__dir__, '../../lib/rls_multi_tenant/generators/model/model_generator.rb')
      expect(File.exist?(generator_path)).to be true
    end

    it 'generator can be loaded' do
      generator_path = File.join(__dir__, '../../lib/rls_multi_tenant/generators/model/model_generator.rb')
      expect { load generator_path }.not_to raise_error
    end
  end
end
