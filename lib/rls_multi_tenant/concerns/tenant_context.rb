# frozen_string_literal: true

module RlsMultiTenant
  module Concerns
    module TenantContext
      extend ActiveSupport::Concern

      SET_TENANT_ID_SQL = 'SET rls.tenant_id = %s'.freeze
      RESET_TENANT_ID_SQL = 'RESET rls.tenant_id'.freeze

      class_methods do
        # Switch tenant context for a block
        def switch(tenant_or_id)
          tenant_id = extract_tenant_id(tenant_or_id)
          connection.execute format(SET_TENANT_ID_SQL, connection.quote(tenant_id))
          yield
        ensure
          reset!
        end

        # Switch tenant context permanently (until reset)
        def switch!(tenant_or_id)
          tenant_id = extract_tenant_id(tenant_or_id)
          connection.execute format(SET_TENANT_ID_SQL, connection.quote(tenant_id))
        end

        # Reset tenant context
        def reset!
          connection.execute RESET_TENANT_ID_SQL
        end

        # Get current tenant from context
        def current
          return nil unless connection.active?

          result = connection.execute("SHOW rls.tenant_id")
          tenant_id = result.first&.dig('rls.tenant_id')
          
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
            raise ArgumentError, "Expected #{RlsMultiTenant.tenant_class_name} object or tenant_id, got #{tenant_or_id.class}"
          end
        end
      end

      # Instance methods
      def switch(tenant_or_id)
        self.class.switch(tenant_or_id) { yield }
      end

      def switch!(tenant_or_id)
        self.class.switch!(tenant_or_id)
      end

      def reset!
        self.class.reset!
      end
    end
  end
end
