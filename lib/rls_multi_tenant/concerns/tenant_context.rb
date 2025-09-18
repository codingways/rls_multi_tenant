# frozen_string_literal: true

module RlsMultiTenant
  module Concerns
    module TenantContext
      extend ActiveSupport::Concern

      SET_TENANT_ID_SQL = 'SET %s = %s'
      RESET_TENANT_ID_SQL = 'RESET %s'

      class_methods do
        def tenant_session_var
          "rls.#{RlsMultiTenant.tenant_id_column}"
        end

        # Switch tenant context for a block
        def switch(tenant_or_id)
          tenant_id = extract_tenant_id(tenant_or_id)
          validate_tenant_exists!(tenant_id)
          connection.execute format(SET_TENANT_ID_SQL, tenant_session_var, connection.quote(tenant_id))
          yield
        ensure
          reset!
        end

        # Switch tenant context permanently (until reset)
        def switch!(tenant_or_id)
          tenant_id = extract_tenant_id(tenant_or_id)
          validate_tenant_exists!(tenant_id)
          connection.execute format(SET_TENANT_ID_SQL, tenant_session_var, connection.quote(tenant_id))
        end

        # Reset tenant context
        def reset!
          connection.execute format(RESET_TENANT_ID_SQL, tenant_session_var)
        end

        # Get current tenant from context
        def current
          return nil unless connection.active?

          result = connection.execute("SHOW #{tenant_session_var}")
          tenant_id = result.first&.dig(tenant_session_var)

          return nil if tenant_id.blank?

          RlsMultiTenant.tenant_class.find_by(id: tenant_id)
        rescue ActiveRecord::StatementInvalid, PG::Error
          nil
        end

        private

        def extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when RlsMultiTenant.tenant_class
            tenant_or_id.id
          when String, Integer
            tenant_or_id
          else
            raise ArgumentError,
                  "Expected #{RlsMultiTenant.tenant_class_name} object or tenant_id, got #{tenant_or_id.class}"
          end
        end

        def validate_tenant_exists!(tenant_id)
          return if tenant_id.blank?

          return if RlsMultiTenant.tenant_class.exists?(id: tenant_id)

          raise StandardError, "#{RlsMultiTenant.tenant_class_name} with id '#{tenant_id}' not found"
        end
      end

      # Instance methods
      def switch(tenant_or_id, &block)
        self.class.switch(tenant_or_id, &block)
      end

      delegate :switch!, to: :class

      delegate :reset!, to: :class
    end
  end
end
