class EnableRlsFor<%= table_name.camelize %> < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    reversible do |dir|
      dir.up do
        # Enable Row Level Security
        execute 'ALTER TABLE <%= table_name %> ENABLE ROW LEVEL SECURITY'
        
        # Create RLS policy
        execute "CREATE POLICY <%= table_name %>_app_user ON <%= table_name %> TO #{ENV['<%= RlsMultiTenant.app_user_env_var %>']} USING (<%= RlsMultiTenant.tenant_id_column %> = NULLIF(current_setting('rls.tenant_id', TRUE), '')::uuid)"
        
        # Grant permissions
        execute "GRANT SELECT, INSERT, UPDATE, DELETE ON <%= table_name %> TO #{ENV['<%= RlsMultiTenant.app_user_env_var %>']}"
      end
      
      dir.down do
        # Revoke permissions
        execute "REVOKE SELECT, INSERT, UPDATE, DELETE ON <%= table_name %> FROM #{ENV['<%= RlsMultiTenant.app_user_env_var %>']}"
        
        # Drop policy
        execute "DROP POLICY <%= table_name %>_app_user ON <%= table_name %>"
        
        # Disable RLS
        execute "ALTER TABLE <%= table_name %> DISABLE ROW LEVEL SECURITY"
      end
    end
  end
end
