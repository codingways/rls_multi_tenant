# frozen_string_literal: true

require 'rails/generators'
require 'rls_multi_tenant/generators/shared/template_helper'

module RlsMultiTenant
  module Generators
    class SetupGenerator < Rails::Generators::Base
      include Shared::TemplateHelper
      
      source_root File.expand_path("templates", __dir__)

      desc "Setup RLS Multi-tenant gem with tenant model and migrations"

      def create_tenant_model
        tenant_class_name = RlsMultiTenant.tenant_class_name
        tenant_file_path = "app/models/#{tenant_class_name.underscore}.rb"
        
        unless File.exist?(File.join(destination_root, tenant_file_path))
          template "tenant_model.rb", tenant_file_path
        else
          say "#{tenant_class_name} model already exists, skipping creation", :yellow
        end
      end

      def create_db_admin_task
        unless File.exist?(File.join(destination_root, "lib/tasks/db_admin.rake"))
          copy_shared_template "db_admin.rake", "lib/tasks/db_admin.rake"
        else
          say "Database admin task already exists, skipping creation", :yellow
        end
      end

      def create_uuid_migration
        unless Dir.glob(File.join(destination_root, "db/migrate/*_enable_uuid_extension.rb")).any?
          create_migration_with_timestamp("enable_uuid", 1)
        else
          say "UUID extension migration already exists, skipping creation", :yellow
        end
      end

      def create_app_user_migration
        create_app_user_migrations_for_all_databases
      end

      def create_tenant_migration
        tenant_class_name = RlsMultiTenant.tenant_class_name
        migration_pattern = "*_create_#{tenant_class_name.underscore.pluralize}.rb"
        
        unless Dir.glob(File.join(destination_root, "db/migrate/#{migration_pattern}")).any?
          create_migration_with_timestamp("create_tenant", 3)
        else
          say "#{tenant_class_name} migration already exists, skipping creation", :yellow
        end
      end

      def show_instructions
        tenant_class_name = RlsMultiTenant.tenant_class_name
        say "\n" + "="*60, :green
        say "RLS Multi-tenant setup completed successfully!", :green
        say "="*60, :green
        say "\nCreated:", :yellow
        say "• #{tenant_class_name} model", :green
        say "• Database admin task", :green
        say "• UUID extension migration", :green
        say "• App user migration(s)", :green
        say "• #{tenant_class_name} migration", :green
        say "\nNext steps:", :yellow
        say "1. Make sure to use the POSTGRES_APP_USER in your database.yml.", :yellow
        say "\n2. Run the migrations with admin privileges:\n", :yellow
        say "   rails db_as:admin[migrate]", :yellow
        say "   Note: We must use the admin user because the app user doesn't have migration privileges", :yellow
        say "\n3. Use 'rails generate rls_multi_tenant:model' for new multi-tenant models", :yellow
        say "="*60, :green
      end

      private

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
              
              # Check if migration already exists in this path
              unless Dir.glob(File.join(migration_dir, "*_create_app_user.rb")).any?
                FileUtils.mkdir_p(migration_dir) unless File.directory?(migration_dir)
                create_migration_with_timestamp_for_path("create_app_user", 2, migration_path)
                say "Created app user migration for #{db_name} in #{migration_path}", :green
              else
                say "App user migration already exists for #{db_name} in #{migration_path}, skipping creation", :yellow
              end
            end
          else
            say "No migrations_paths defined for database '#{db_name}', skipping app user migration", :yellow
          end
        end

        # Handle primary database (default behavior)
        unless Dir.glob(File.join(destination_root, "db/migrate/*_create_app_user.rb")).any?
          create_migration_with_timestamp("create_app_user", 2)
        else
          say "App user migration already exists for primary database, skipping creation", :yellow
        end
      end

      def create_migration_with_timestamp(migration_type, order)
        base_timestamp = Time.current.strftime("%Y%m%d%H%M")
        timestamp = "#{base_timestamp}#{sprintf('%02d', order)}"
        
        case migration_type
        when "enable_uuid"
          copy_shared_template "enable_uuid_extension.rb", "db/migrate/#{timestamp}_enable_uuid_extension.rb"
        when "create_app_user"
          copy_shared_template "create_app_user.rb", "db/migrate/#{timestamp}_create_app_user.rb"
        when "create_tenant"
          tenant_class_name = RlsMultiTenant.tenant_class_name
          copy_shared_template "create_tenant.rb", "db/migrate/#{timestamp}_create_#{tenant_class_name.underscore.pluralize}.rb"
        end
      end

      def create_migration_with_timestamp_for_path(migration_type, order, migration_path)
        base_timestamp = Time.current.strftime("%Y%m%d%H%M")
        timestamp = "#{base_timestamp}#{sprintf('%02d', order)}"
        
        case migration_type
        when "create_app_user"
          copy_shared_template "create_app_user.rb", "#{migration_path}/#{timestamp}_create_app_user.rb"
        end
      end
    end
  end
end
