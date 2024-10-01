class AddDataAppTokenToDataApps < ActiveRecord::Migration[7.1]
  def change
    add_column :data_apps, :data_app_token, :string
  end
end
