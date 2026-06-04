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
          ensure_tenant_context!(current_tenant)

          column = RlsMultiTenant.tenant_id_column
          ensure_same_tenant!(send(column), current_tenant)
          send("#{column}=", current_tenant.id)
        end

        def ensure_tenant_context!(current_tenant)
          return unless current_tenant.nil?

          raise RlsMultiTenant::Error,
                "Cannot create #{self.class.name} without tenant context. " \
                'This model requires a tenant context. '
        end

        # Reject an explicit tenant_id that points at a different tenant than the
        # active context. The database (FORCE RLS + WITH CHECK) is the real
        # guard, but failing fast here prevents silently building a record that
        # the policy will reject, and blocks cross-tenant writes at the
        # application layer as defense in depth.
        def ensure_same_tenant!(assigned, current_tenant)
          return if assigned.blank? || assigned.to_s == current_tenant.id.to_s

          raise RlsMultiTenant::Error,
                "Cannot assign #{self.class.name} to a different tenant than the current context."
        end
      end
    end
  end
end
