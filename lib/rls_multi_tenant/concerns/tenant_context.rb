# frozen_string_literal: true

module RlsMultiTenant
  module Concerns
    module TenantContext
      extend ActiveSupport::Concern

      # PostgreSQL unquoted identifier pattern, used to validate the configured
      # tenant id column before embedding it in a GUC name.
      IDENTIFIER_PATTERN = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/

      SET_TENANT_ID_SQL = 'SET %s = %s'
      SET_LOCAL_TENANT_ID_SQL = 'SET LOCAL %s = %s'
      RESET_TENANT_ID_SQL = 'RESET %s'
      RESET_LOCAL_TENANT_ID_SQL = 'SET LOCAL %s TO DEFAULT'

      # rubocop:disable Metrics/BlockLength
      class_methods do
        def tenant_session_var
          column = RlsMultiTenant.tenant_id_column.to_s
          unless column.match?(IDENTIFIER_PATTERN)
            raise ConfigurationError, "Invalid tenant_id_column: #{RlsMultiTenant.tenant_id_column.inspect}"
          end

          "rls.#{column}"
        end

        # Switch tenant context for a block.
        #
        # Uses SET LOCAL inside a transaction so PostgreSQL itself scopes the
        # tenant context to the transaction and guarantees it is cleared when
        # the transaction ends — even if the block raises or the process dies
        # mid-request. This prevents the context from leaking onto a pooled
        # connection and being reused by a different tenant's request.
        def switch(tenant_or_id)
          tenant_id = extract_tenant_id(tenant_or_id)
          validate_tenant_exists!(tenant_id)

          connection.transaction(requires_new: true) do
            previous_tenant_id = current_tenant_id
            apply_tenant_context(tenant_id, local: true)
            begin
              yield
            ensure
              restore_tenant_context(previous_tenant_id)
            end
          end
        end

        # Switch tenant context permanently (until reset).
        #
        # WARNING: this sets a session-level variable that persists on the
        # connection until reset! is called. On a pooled connection it can leak
        # to subsequent requests. Prefer the block form `switch` whenever
        # possible; only use switch! for the console or single-tenant scripts,
        # and always pair it with reset!.
        def switch!(tenant_or_id)
          tenant_id = extract_tenant_id(tenant_or_id)
          validate_tenant_exists!(tenant_id)
          apply_tenant_context(tenant_id, local: false)
        end

        # Reset tenant context
        def reset!
          connection.execute format(RESET_TENANT_ID_SQL, tenant_session_var)
        end

        # Get current tenant from context
        def current
          return nil unless connection.active?

          result = connection.execute("SELECT current_setting(#{connection.quote(tenant_session_var)}, true) AS tenant_id")
          tenant_id = result.first&.dig('tenant_id')

          return nil if tenant_id.blank?

          RlsMultiTenant.tenant_class.find_by(id: tenant_id)
        rescue ActiveRecord::StatementInvalid, PG::Error
          nil
        end

        private

        # Restore the previous context on the way out of a `switch` block.
        # If the block aborted the transaction (e.g. a policy violation), any
        # further statement raises until rollback; that rollback will clear the
        # SET LOCAL anyway, so the failure is safe to ignore and we must not let
        # it mask the original error escaping the block.
        def restore_tenant_context(previous_tenant_id)
          apply_tenant_context(previous_tenant_id, local: true)
        rescue ActiveRecord::StatementInvalid
          nil
        end

        # Apply (or clear, when tenant_id is blank) the tenant context.
        # local: true uses SET LOCAL (transaction-scoped); false uses session SET.
        def apply_tenant_context(tenant_id, local:)
          if tenant_id.blank?
            reset_sql = local ? RESET_LOCAL_TENANT_ID_SQL : RESET_TENANT_ID_SQL
            connection.execute format(reset_sql, tenant_session_var)
          else
            set_sql = local ? SET_LOCAL_TENANT_ID_SQL : SET_TENANT_ID_SQL
            connection.execute format(set_sql, tenant_session_var, connection.quote(tenant_id))
          end
        end

        def current_tenant_id
          return nil unless connection.active?

          result = connection.execute("SELECT current_setting(#{connection.quote(tenant_session_var)}, true) AS tenant_id")
          result.first&.dig('tenant_id')
        rescue ActiveRecord::StatementInvalid, PG::Error
          nil
        end

        def extract_tenant_id(tenant_or_id)
          case tenant_or_id
          when nil
            nil
          when ->(obj) { obj.is_a?(RlsMultiTenant.tenant_class) }
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
      # rubocop:enable Metrics/BlockLength

      # Instance methods
      def switch(tenant_or_id, &block)
        self.class.switch(tenant_or_id, &block)
      end

      delegate :switch!, to: :class

      delegate :reset!, to: :class
    end
  end
end
