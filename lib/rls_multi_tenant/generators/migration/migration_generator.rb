# frozen_string_literal: true

require 'rails/generators'
require 'rls_multi_tenant/generators/shared/template_helper'

module RlsMultiTenant
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      include Shared::TemplateHelper
      
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
        create_app_user_migrations_for_all_databases
      end

      def create_enable_rls_migration
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        template "enable_rls.rb", "db/migrate/#{timestamp}_enable_rls_for_#{table_name}.rb"
      end

      def create_tenant_migration
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        copy_shared_template "create_tenant.rb", "db/migrate/#{timestamp}_create_tenant.rb"
      end

      def create_enable_uuid_migration
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        copy_shared_template "enable_uuid_extension.rb", "db/migrate/#{timestamp}_enable_uuid_extension.rb"
      end

      def create_app_user_migrations_for_all_databases
        # Get database configuration for current environment
        db_config = Rails.application.config.database_configuration[Rails.env]
        
        # Handle both single database and multiple databases configuration
        databases_to_process = if db_config.is_a?(Hash) && db_config.key?('primary')
          # Multiple databases configuration
          db_config
        else
          # Single database configuration - treat as primary
          { 'primary' => db_config }
        end

        databases_to_process.each do |db_name, config|
          next if db_name == 'primary' # Skip primary database, handle it separately
          
          # Check if migrations_paths is defined for this database
          if config['migrations_paths']
            migration_paths = Array(config['migrations_paths'])
            migration_paths.each do |migration_path|
              migration_dir = File.join(destination_root, migration_path)
              FileUtils.mkdir_p(migration_dir) unless File.directory?(migration_dir)
              
              timestamp = Time.current.strftime("%Y%m%d%H%M%S")
              copy_shared_template "create_app_user.rb", "#{migration_path}/#{timestamp}_create_app_user.rb"
              say "Created app user migration for #{db_name} in #{migration_path}", :green
            end
          else
            say "No migrations_paths defined for database '#{db_name}', skipping app user migration", :yellow
          end
        end

        # Handle primary database (default behavior)
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        copy_shared_template "create_app_user.rb", "db/migrate/#{timestamp}_create_app_user.rb"
        say "Created app user migration for primary database", :green
      end

      def table_name
        @table_name ||= ask("Enter table name for RLS:")
      end
    end
  end
end
