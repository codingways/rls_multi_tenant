# frozen_string_literal: true

module RlsMultiTenant
  module RlsHelper
    class << self
      # Enable RLS on a table with a policy
      def enable_rls_for_table(table_name, tenant_column: RlsMultiTenant.tenant_id_column)
        # Enable RLS
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table_name} ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY")

        # Create policy (drop if exists first)
        policy_name = "#{table_name}_app_user"
        ActiveRecord::Base.connection.execute("DROP POLICY IF EXISTS #{policy_name} ON #{table_name}")

        tenant_session_var = "rls.#{RlsMultiTenant.tenant_id_column}"
        policy_sql = "CREATE POLICY #{policy_name} ON #{table_name} " \
                     "USING (#{tenant_column} = NULLIF(current_setting('#{tenant_session_var}', TRUE), '')::uuid)"

        ActiveRecord::Base.connection.execute(policy_sql)

        Rails.logger&.info "✅ RLS enabled for table #{table_name} with policy #{policy_name}"
      end

      # Disable RLS on a table
      def disable_rls_for_table(table_name)
        # Drop policy
        policy_name = "#{table_name}_app_user"
        ActiveRecord::Base.connection.execute("DROP POLICY IF EXISTS #{policy_name} ON #{table_name}")

        # Disable RLS
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table_name} DISABLE ROW LEVEL SECURITY, NO FORCE ROW LEVEL SECURITY")

        Rails.logger&.info "✅ RLS disabled for table #{table_name}"
      end

      # Check if RLS is enabled on a table
      def rls_enabled?(table_name)
        result = ActiveRecord::Base.connection.execute(
          "SELECT relrowsecurity FROM pg_class WHERE relname = '#{table_name}'"
        ).first

        result&.dig('relrowsecurity') == true && result&.dig('relforcerowsecurity') == true
      end

      # Get all RLS policies for a table
      def rls_policies(table_name)
        ActiveRecord::Base.connection.execute(
          "SELECT policyname, permissive, roles, cmd, qual FROM pg_policies WHERE tablename = '#{table_name}'"
        )
      end
    end
  end
end
