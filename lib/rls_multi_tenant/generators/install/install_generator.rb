# frozen_string_literal: true

require 'rails/generators'

module RlsMultiTenant
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install RLS Multi-tenant gem configuration and initial setup"

      def create_initializer
        template "rls_multi_tenant.rb", "config/initializers/rls_multi_tenant.rb"
      end

      def create_tenant_model
        unless File.exist?(File.join(destination_root, "app/models/tenant.rb"))
          template "tenant_model.rb", "app/models/tenant.rb"
        else
          say "Tenant model already exists, skipping creation", :yellow
        end
      end

      def create_db_admin_task
        unless File.exist?(File.join(destination_root, "lib/tasks/db_admin.rake"))
          template "db_admin.rake", "lib/tasks/db_admin.rake"
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
        unless Dir.glob(File.join(destination_root, "db/migrate/*_create_app_user.rb")).any?
          create_migration_with_timestamp("create_app_user", 2)
        else
          say "App user migration already exists, skipping creation", :yellow
        end
      end

      def create_tenant_migration
        unless Dir.glob(File.join(destination_root, "db/migrate/*_create_tenants.rb")).any?
          create_migration_with_timestamp("create_tenant", 3)
        else
          say "Tenant migration already exists, skipping creation", :yellow
        end
      end

      def show_instructions
        say "\n" + "="*60, :green
        say "RLS Multi-tenant gem installed successfully!", :green
        say "="*60, :green
        say "\nNext steps:", :yellow
        say "1. Configure your environment variables:\n", :yellow
        say "   POSTGRES_USER=your_admin_user # This is the user that will run the migrations", :yellow
        say "   POSTGRES_PASSWORD=your_admin_user_password", :yellow
        say "   POSTGRES_APP_USER=your_app_user # This is the user that will run the app", :yellow
        say "   POSTGRES_APP_PASSWORD=your_app_user_password", :yellow
        say "\n2. Make sure to use the POSTGRES_APP_USER in your database.yml.", :yellow
        say "\n3. Run the migrations with admin privileges:\n", :yellow
        say "   rails db_as:admin[migrate]", :yellow
        say "   Note: We must use the admin user because the app user doesn't have migration privileges", :yellow
        say "\n4. Use 'rails generate rls_multi_tenant:model' for new multi-tenant models", :yellow
        say "="*60, :green
      end

      private

      def create_migration_with_timestamp(migration_type, order)
        base_timestamp = Time.current.strftime("%Y%m%d%H%M")
        timestamp = "#{base_timestamp}#{sprintf('%02d', order)}"
        
        case migration_type
        when "enable_uuid"
          template "enable_uuid_extension.rb", "db/migrate/#{timestamp}_enable_uuid_extension.rb"
        when "create_app_user"
          template "create_app_user.rb", "db/migrate/#{timestamp}_create_app_user.rb"
        when "create_tenant"
          template "create_tenant.rb", "db/migrate/#{timestamp}_create_tenants.rb"
        end
      end
    end
  end
end
