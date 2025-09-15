class EnableUuidExtension < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    enable_extension 'uuid-ossp'
  end
end
