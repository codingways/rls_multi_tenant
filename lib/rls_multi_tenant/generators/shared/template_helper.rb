# frozen_string_literal: true

module RlsMultiTenant
  module Generators
    module Shared
      module TemplateHelper
        extend ActiveSupport::Concern

        private

        def shared_template_path
          File.expand_path("templates", File.dirname(__FILE__))
        end

        def copy_shared_template(template_name, destination_path)
          template_path = File.join(shared_template_path, template_name)
          copy_file template_path, destination_path
        end

        def shared_template_exists?(template_name)
          File.exist?(File.join(shared_template_path, template_name))
        end

        def render_shared_template(template_name, destination_path, context = {})
          template_path = File.join(shared_template_path, template_name)
          template template_path, destination_path, context
        end
      end
    end
  end
end
