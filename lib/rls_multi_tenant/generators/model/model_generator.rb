# frozen_string_literal: true

require 'rails/generators'

module RlsMultiTenant
  module Generators
    class ModelGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, desc: "Model name"
      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      def initialize(args, *options)
        super
        @attributes = parse_attributes!
      end

      desc "Generate a multi-tenant model with RLS policies"

      def create_model_file
        template "model.rb", File.join("app/models", "#{model_name.underscore}.rb")
      end

      def create_migration
        template "migration.rb", File.join("db/migrate", "#{migration_file_name}.rb")
      end

      def show_instructions
        say "\n" + "="*60, :green
        say "Multi-tenant model '#{model_name}' created successfully!", :green
        say "="*60, :green
        say "\nWhat was created:", :yellow
        say "1. Model: app/models/#{model_name.underscore}.rb (with MultiTenant concern included)", :yellow
        say "2. Migration: #{migration_file_name}.rb (with tenant_id column and RLS policies)", :yellow
        say "\nNext steps:", :yellow
        say "1. Run migrations: rails db_as:admin[migrate]", :yellow
        say "2. The model is ready to use with multi-tenant functionality", :yellow
        say "3. RLS policies are automatically configured", :yellow
        say "="*60, :green
      end

      private

      def model_name
        @model_name ||= name.classify
      end

      def table_name
        @table_name ||= name.underscore.pluralize
      end

      def migration_file_name
        "#{migration_timestamp}_create_#{table_name}"
      end

      def migration_timestamp
        Time.current.strftime("%Y%m%d%H%M%S")
      end

      def tenant_id_column
        RlsMultiTenant.tenant_id_column
      end

      def tenant_class_name
        RlsMultiTenant.tenant_class_name
      end

      def migration_class_name
        "Create#{model_name.pluralize}"
      end

      def parse_attributes!
        attributes.map do |attr|
          name, type = attr.split(':')
          { name: name, type: type || 'string' }
        end
      end
    end
  end
end