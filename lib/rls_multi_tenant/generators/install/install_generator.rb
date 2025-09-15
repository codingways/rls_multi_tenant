# frozen_string_literal: true

require 'rails/generators'
require 'rls_multi_tenant/generators/shared/template_helper'

module RlsMultiTenant
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Shared::TemplateHelper

      source_root File.expand_path("templates", __dir__)

      desc "Install RLS Multi-tenant gem configuration"

      def create_initializer
        template "rls_multi_tenant.rb", "config/initializers/rls_multi_tenant.rb"
      end

      def create_db_admin_task
        unless File.exist?(File.join(destination_root, "lib/tasks/db_admin.rake"))
          copy_shared_template "db_admin.rake", "lib/tasks/db_admin.rake"
        else
          say "Database admin task already exists, skipping creation", :yellow
        end
      end

      def show_instructions
        say "\n" + "="*60, :green
        say "RLS Multi-tenant gem configuration installed successfully!", :green
        say "="*60, :green
        say "\nNext steps:", :yellow
        say "1. Configure your environment variables:\n", :yellow
        say "   POSTGRES_USER=your_admin_user # This is the user that will run the migrations", :yellow
        say "   POSTGRES_PASSWORD=your_admin_user_password", :yellow
        say "   POSTGRES_APP_USER=your_app_user # This is the user that will run the app", :yellow
        say "   POSTGRES_APP_PASSWORD=your_app_user_password", :yellow
        say "\n2. Configure the gem settings in config/initializers/rls_multi_tenant.rb", :yellow
        say "   (tenant_class_name, tenant_id_column, app_user_env_var, enable_security_validation)", :yellow
        say "\n3. Run the setup generator to create the tenant model and migrations:\n", :yellow
        say "   rails generate rls_multi_tenant:setup", :yellow
        say "\n4. Make sure to use the POSTGRES_APP_USER in your database.yml.", :yellow
        say "\n5. Run the migrations with admin privileges:\n", :yellow
        say "   rails db_as:admin[migrate]", :yellow
        say "   Note: We must use the admin user because the app user doesn't have migration privileges", :yellow
        say "\n6. Use 'rails generate rls_multi_tenant:model' for new multi-tenant models", :yellow
        say "="*60, :green
      end

    end
  end
end
