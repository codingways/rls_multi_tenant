# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Migration Generator Tests' do
  describe 'RLS migration template content' do
    let(:template_path) { File.join(__dir__, '../../lib/rls_multi_tenant/generators/migration/templates/enable_rls.rb') }
    
    it 'template file exists' do
      expect(File.exist?(template_path)).to be true
    end

    it 'contains RLS enable statement' do
      template_content = File.read(template_path)
      expect(template_content).to include('ALTER TABLE <%= table_name %> ENABLE ROW LEVEL SECURITY')
    end

    it 'contains RLS policy creation' do
      template_content = File.read(template_path)
      expect(template_content).to include('CREATE POLICY <%= table_name %>_app_user ON <%= table_name %>')
    end

    it 'contains tenant_id column reference' do
      template_content = File.read(template_path)
      expect(template_content).to include('<%= RlsMultiTenant.tenant_id_column %>')
    end

    it 'contains environment variable reference' do
      template_content = File.read(template_path)
      expect(template_content).to include('ENV[\'<%= RlsMultiTenant.app_user_env_var %>\']')
    end

    it 'contains rollback functionality' do
      template_content = File.read(template_path)
      expect(template_content).to include('dir.down do')
      expect(template_content).to include('DROP POLICY <%= table_name %>_app_user ON <%= table_name %>')
      expect(template_content).to include('ALTER TABLE <%= table_name %> DISABLE ROW LEVEL SECURITY')
    end

    it 'uses correct Rails migration version' do
      template_content = File.read(template_path)
      expect(template_content).to include('ActiveRecord::Migration[<%= Rails.version.to_f %>]')
    end
  end

  describe 'Migration generator class' do
    it 'generator file exists' do
      generator_path = File.join(__dir__, '../../lib/rls_multi_tenant/generators/migration/migration_generator.rb')
      expect(File.exist?(generator_path)).to be true
    end

    it 'generator can be loaded' do
      generator_path = File.join(__dir__, '../../lib/rls_multi_tenant/generators/migration/migration_generator.rb')
      expect { load generator_path }.not_to raise_error
    end
  end

  describe 'Template helper methods' do
    let(:template_path) { File.join(__dir__, '../../lib/rls_multi_tenant/generators/migration/templates/enable_rls.rb') }
    
    it 'template uses proper ERB syntax' do
      template_content = File.read(template_path)
      # Check for proper ERB syntax
      expect(template_content).to match(/<%= .+ %>/)
      expect(template_content).to include('end')
    end

    it 'template has proper class structure' do
      template_content = File.read(template_path)
      expect(template_content).to include('class EnableRlsFor<%= table_name.camelize %>')
    end

    it 'template includes reversible migration' do
      template_content = File.read(template_path)
      expect(template_content).to include('reversible do |dir|')
    end
  end
end
