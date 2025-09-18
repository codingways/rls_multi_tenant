class EnableRlsFor<%= table_name.camelize %> < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    reversible do |dir|
      dir.up do
        # Enable and force Row Level Security
        execute 'ALTER TABLE <%= table_name %> ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY'
        
        # Create RLS policy
        execute "CREATE POLICY <%= table_name %>_app_user ON <%= table_name %> USING (<%= RlsMultiTenant.tenant_id_column %> = NULLIF(current_setting('rls.<%= RlsMultiTenant.tenant_id_column %>', TRUE), '')::uuid)"
      end
      
      dir.down do
        # Drop policy
        execute "DROP POLICY <%= table_name %>_app_user ON <%= table_name %>"
        
        # Disable RLS
        execute "ALTER TABLE <%= table_name %> DISABLE ROW LEVEL SECURITY, NO FORCE ROW LEVEL SECURITY"
      end
    end
  end
end
