class <%= migration_class_name %> < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    # Create the table
    create_table :<%= table_name %> do |t|
      t.references :<%= tenant_id_column.to_s.gsub('_id', '') %>, null: false, foreign_key: { to_table: :<%= tenant_class_name.underscore.pluralize %> }, type: :uuid
<% @attributes.each do |attribute| -%>
      t.<%= attribute[:type] %> :<%= attribute[:name] %>
<% end -%>

      t.timestamps
    end

    # Enable Row Level Security
    execute "ALTER TABLE <%= table_name %> ENABLE ROW LEVEL SECURITY"

    # Define RLS policy
    reversible do |dir|
      dir.up do
        execute "CREATE POLICY <%= table_name %>_app_user ON <%= table_name %> TO #{ENV['<%= RlsMultiTenant.app_user_env_var %>']} USING (<%= tenant_id_column %> = NULLIF(current_setting('rls.<%= tenant_id_column %>', TRUE), '')::uuid)"
      end
      dir.down do
        execute "DROP POLICY <%= table_name %>_app_user ON <%= table_name %>"
      end
    end
  end
end
