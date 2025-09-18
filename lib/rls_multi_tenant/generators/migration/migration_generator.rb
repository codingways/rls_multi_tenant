# frozen_string_literal: true

require 'rails/generators'
require 'rls_multi_tenant/generators/shared/template_helper'

module RlsMultiTenant
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      include Shared::TemplateHelper

      source_root File.expand_path('templates', __dir__)

      argument :migration_type, type: :string, desc: 'Type of migration to generate'

      desc 'Generate RLS Multi-tenant migrations'

      def create_migration
        case migration_type
        when 'create_tenant'
          create_tenant_migration
        when 'enable_rls'
          create_enable_rls_migration
        when 'enable_uuid'
          create_enable_uuid_migration
        else
          say "Unknown migration type: #{migration_type}", :red
          say 'Available types: create_tenant, enable_rls, enable_uuid', :yellow
        end
      end

      private

      def create_enable_rls_migration
        timestamp = Time.current.strftime('%Y%m%d%H%M%S')
        template 'enable_rls.rb', "db/migrate/#{timestamp}_enable_rls_for_#{table_name}.rb"
      end

      def create_tenant_migration
        tenant_class_name = RlsMultiTenant.tenant_class_name
        migration_pattern = "*_create_#{tenant_class_name.underscore.pluralize}.rb"

        if Dir.glob(File.join(destination_root, "db/migrate/#{migration_pattern}")).any?
          say "#{tenant_class_name} migration already exists, skipping creation", :yellow
        else
          timestamp = Time.current.strftime('%Y%m%d%H%M%S')
          render_shared_template 'create_tenant.rb',
                                 "db/migrate/#{timestamp}_create_#{tenant_class_name.underscore.pluralize}.rb"
        end
      end

      def create_enable_uuid_migration
        if Dir.glob(File.join(destination_root, 'db/migrate/*_enable_uuid_extension.rb')).any?
          say 'UUID extension migration already exists, skipping creation', :yellow
        else
          timestamp = Time.current.strftime('%Y%m%d%H%M%S')
          render_shared_template 'enable_uuid_extension.rb', "db/migrate/#{timestamp}_enable_uuid_extension.rb"
        end
      end

      def table_name
        @table_name ||= ask('Enter table name for RLS:')
      end
    end
  end
end
