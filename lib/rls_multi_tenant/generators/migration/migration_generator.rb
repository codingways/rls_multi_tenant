# frozen_string_literal: true

require 'rails/generators'

module RlsMultiTenant
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      argument :migration_type, type: :string, desc: "Type of migration to generate"

      desc "Generate RLS Multi-tenant migrations"

      def create_migration
        case migration_type
        when "create_tenant"
          create_tenant_migration
        when "create_app_user"
          create_app_user_migration
        when "enable_rls"
          create_enable_rls_migration
        when "enable_uuid"
          create_enable_uuid_migration
        else
          say "Unknown migration type: #{migration_type}", :red
          say "Available types: create_tenant, create_app_user, enable_rls, enable_uuid", :yellow
        end
      end

      private

      def create_app_user_migration
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        template "create_app_user.rb", "db/migrate/#{timestamp}_create_app_user.rb"
      end

      def create_enable_rls_migration
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        template "enable_rls.rb", "db/migrate/#{timestamp}_enable_rls_for_#{table_name}.rb"
      end

      def create_tenant_migration
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        template "create_tenant.rb", "db/migrate/#{timestamp}_create_tenant.rb"
      end

      def create_enable_uuid_migration
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        template "enable_uuid_extension.rb", "db/migrate/#{timestamp}_enable_uuid_extension.rb"
      end

      def table_name
        @table_name ||= ask("Enter table name for RLS:")
      end
    end
  end
end
