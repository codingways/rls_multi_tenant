# frozen_string_literal: true

module RlsMultiTenant
  module Concerns
    module MultiTenant
      extend ActiveSupport::Concern

      included do
        belongs_to :tenant, class_name: RlsMultiTenant.tenant_class_name, foreign_key: RlsMultiTenant.tenant_id_column
        
        validates RlsMultiTenant.tenant_id_column, presence: true

        before_validation :set_tenant_id

        private

        def set_tenant_id
          current_tenant = RlsMultiTenant.tenant_class.current
          self.send("#{RlsMultiTenant.tenant_id_column}=", current_tenant&.id) if current_tenant
        end
      end

      class_methods do
        private

        def extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when RlsMultiTenant.tenant_class
            tenant_or_id.id
          when String, Integer
            tenant_or_id
          else
            raise ArgumentError, "Expected #{RlsMultiTenant.tenant_class_name} object or tenant_id, got #{tenant_or_id.class}"
          end
        end
      end
    end
  end
end
