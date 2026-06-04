# frozen_string_literal: true

module RlsMultiTenant
  module RlsHelper
    # PostgreSQL unquoted identifier: starts with a letter or underscore,
    # followed by letters, digits or underscores.
    IDENTIFIER_PATTERN = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/

    class << self
      # Enable RLS on a table with a policy
      def enable_rls_for_table(table_name, tenant_column: RlsMultiTenant.tenant_id_column)
        table = quoted_table(table_name)
        column = quoted_column(tenant_column)
        policy = quoted_policy_name(table_name)

        # Enable RLS
        connection.execute("ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY")

        # Create policy (drop if exists first)
        connection.execute("DROP POLICY IF EXISTS #{policy} ON #{table}")

        tenant_session_var = "rls.#{validated_identifier(RlsMultiTenant.tenant_id_column)}"
        policy_sql = "CREATE POLICY #{policy} ON #{table} " \
                     "USING (#{column} = NULLIF(current_setting(#{connection.quote(tenant_session_var)}, TRUE), '')::uuid)"

        connection.execute(policy_sql)

        Rails.logger&.info "✅ RLS enabled for table #{table_name} with policy #{table_name}_app_user"
      end

      # Disable RLS on a table
      def disable_rls_for_table(table_name)
        table = quoted_table(table_name)
        policy = quoted_policy_name(table_name)

        # Drop policy
        connection.execute("DROP POLICY IF EXISTS #{policy} ON #{table}")

        # Disable RLS
        connection.execute("ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY, NO FORCE ROW LEVEL SECURITY")

        Rails.logger&.info "✅ RLS disabled for table #{table_name}"
      end

      # Check if RLS is enabled on a table
      def rls_enabled?(table_name)
        result = connection.execute(
          "SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname = #{connection.quote(table_name.to_s)}"
        ).first

        result&.dig('relrowsecurity') == true && result&.dig('relforcerowsecurity') == true
      end

      # Get all RLS policies for a table
      def rls_policies(table_name)
        connection.execute(
          'SELECT policyname, permissive, roles, cmd, qual FROM pg_policies ' \
          "WHERE tablename = #{connection.quote(table_name.to_s)}"
        )
      end

      private

      def connection
        ActiveRecord::Base.connection
      end

      def quoted_table(table_name)
        connection.quote_table_name(validated_identifier(table_name))
      end

      def quoted_column(column_name)
        connection.quote_column_name(validated_identifier(column_name))
      end

      def quoted_policy_name(table_name)
        connection.quote_column_name("#{validated_identifier(table_name)}_app_user")
      end

      # Guard against SQL injection through identifiers (table/column names),
      # which cannot be passed as bind parameters and must be embedded in the
      # statement text.
      def validated_identifier(identifier)
        value = identifier.to_s
        return value if value.match?(IDENTIFIER_PATTERN)

        raise ArgumentError, "Invalid SQL identifier: #{identifier.inspect}"
      end
    end
  end
end
