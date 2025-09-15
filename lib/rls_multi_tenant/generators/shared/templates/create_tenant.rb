class Create<%= RlsMultiTenant.tenant_class_name.pluralize %> < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    create_table :<%= RlsMultiTenant.tenant_class_name.underscore.pluralize %>, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :<%= RlsMultiTenant.tenant_class_name.underscore.pluralize %>, :name, unique: true
  end
end
