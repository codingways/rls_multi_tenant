# frozen_string_literal: true

require 'rails/generators'
require 'rls_multi_tenant/generators/shared/template_helper'

module RlsMultiTenant
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Shared::TemplateHelper

      source_root File.expand_path('templates', __dir__)

      desc 'Install RLS Multi-tenant gem configuration'

      def create_initializer
        template 'rls_multi_tenant.rb', 'config/initializers/rls_multi_tenant.rb'
      end

      def show_instructions
        say "\n#{'=' * 60}", :green
        say 'RLS Multi-tenant gem configuration installed successfully!', :green
        say '=' * 60, :green
        say "\nNext steps:", :yellow
        say "\n1. Configure the gem settings in config/initializers/rls_multi_tenant.rb", :yellow
        say "\n2. Run the setup generator to create the tenant model and migrations:\n", :yellow
        say '   rails generate rls_multi_tenant:setup', :yellow
        say "\n3. Run migrations:\n", :yellow
        say '   rails db:migrate', :yellow
        say "\n4. Use 'rails generate rls_multi_tenant:model' for new multi-tenant models", :yellow
        say '=' * 60, :green
      end
    end
  end
end
