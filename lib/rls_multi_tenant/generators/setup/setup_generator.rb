# frozen_string_literal: true

require 'rails/generators'
require 'rls_multi_tenant/generators/shared/template_helper'

module RlsMultiTenant
  module Generators
    class SetupGenerator < Rails::Generators::Base
      include Shared::TemplateHelper

      source_root File.expand_path('templates', __dir__)

      desc 'Setup RLS Multi-tenant gem with tenant model and migrations'

      def create_tenant_model
        tenant_class_name = RlsMultiTenant.tenant_class_name
        tenant_file_path = "app/models/#{tenant_class_name.underscore}.rb"

        if File.exist?(File.join(destination_root, tenant_file_path))
          say "#{tenant_class_name} model already exists, skipping creation", :yellow
        else
          template 'tenant_model.rb', tenant_file_path
        end
      end

      def create_uuid_migration
        if Dir.glob(File.join(destination_root, 'db/migrate/*_enable_uuid_extension.rb')).any?
          say 'UUID extension migration already exists, skipping creation', :yellow
        else
          create_migration_with_timestamp('enable_uuid', 1)
        end
      end

      def create_tenant_migration
        tenant_class_name = RlsMultiTenant.tenant_class_name
        migration_pattern = "*_create_#{tenant_class_name.underscore.pluralize}.rb"

        if Dir.glob(File.join(destination_root, "db/migrate/#{migration_pattern}")).any?
          say "#{tenant_class_name} migration already exists, skipping creation", :yellow
        else
          create_migration_with_timestamp('create_tenant', 3)
        end
      end

      def show_instructions
        tenant_class_name = RlsMultiTenant.tenant_class_name
        say "\n#{'=' * 60}", :green
        say 'RLS Multi-tenant setup completed successfully!', :green
        say '=' * 60, :green
        say "\nCreated:", :yellow
        say "• #{tenant_class_name} model", :green
        say '• UUID extension migration', :green
        say "• #{tenant_class_name} migration", :green
        say "\nNext steps:", :yellow
        say "\n1. Use 'rails generate rls_multi_tenant:model <model_name>' for new multi-tenant models", :yellow
        say '=' * 60, :green
      end

      private

      def create_migration_with_timestamp(migration_type, order)
        base_timestamp = Time.current.strftime('%Y%m%d%H%M')
        timestamp = "#{base_timestamp}#{format('%02d', order)}"

        case migration_type
        when 'enable_uuid'
          render_shared_template 'enable_uuid_extension.rb', "db/migrate/#{timestamp}_enable_uuid_extension.rb"
        when 'create_tenant'
          tenant_class_name = RlsMultiTenant.tenant_class_name
          render_shared_template 'create_tenant.rb',
                                 "db/migrate/#{timestamp}_create_#{tenant_class_name.underscore.pluralize}.rb"
        end
      end
    end
  end
end
