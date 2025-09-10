class CreateTenants < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    create_table :tenants, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :tenants, :name, unique: true

    reversible do |dir|
      dir.up do
        execute "GRANT SELECT, INSERT, UPDATE, DELETE ON tenants TO #{ENV['<%= RlsMultiTenant.app_user_env_var %>']}"
      end
      dir.down do
        execute "REVOKE SELECT, INSERT, UPDATE, DELETE ON tenants FROM #{ENV['<%= RlsMultiTenant.app_user_env_var %>']}"
      end
    end
  end
end
