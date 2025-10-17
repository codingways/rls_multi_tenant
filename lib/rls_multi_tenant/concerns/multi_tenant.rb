# frozen_string_literal: true

module RlsMultiTenant
  module Concerns
    module MultiTenant
      extend ActiveSupport::Concern

      included do
        belongs_to :tenant, class_name: RlsMultiTenant.tenant_class_name.to_s,
                            foreign_key: RlsMultiTenant.tenant_id_column

        validates RlsMultiTenant.tenant_id_column, presence: true

        before_validation :set_tenant_id

        private

        def set_tenant_id
          current_tenant = RlsMultiTenant.tenant_class.current

          if current_tenant && send(RlsMultiTenant.tenant_id_column).blank?
            send("#{RlsMultiTenant.tenant_id_column}=", current_tenant.id)
          elsif current_tenant.nil?
            raise RlsMultiTenant::Error,
                  "Cannot create #{self.class.name} without tenant context. " \
                  'This model requires a tenant context. '
          end
        end
      end
    end
  end
end
