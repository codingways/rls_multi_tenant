# frozen_string_literal: true

require 'rails/generators'

module RlsMultiTenant
  module Generators
    class TaskGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Generate RLS Multi-tenant rake tasks"

      def create_db_admin_task
        template "db_admin.rake", "lib/tasks/db_admin.rake"
        show_instructions
      end

      def show_instructions
        say "\n" + "="*60, :green
        say "RLS Multi-tenant rake tasks created successfully!", :green
        say "="*60, :green
        say "\nWhat was created:", :yellow
        say "1. lib/tasks/db_admin.rake - Database admin tasks", :yellow
        say "\nUsage:", :yellow
        say "rails db_as:admin[migrate]    # Run migrations with admin privileges", :yellow
        say "rails db_as:admin[seed]       # Run seeds with admin privileges", :yellow
        say "\nNote: This is required because the app user doesn't have migration privileges", :yellow
        say "="*60, :green
      end
    end
  end
end
