class AddDataAppSessionsCountToDataApps < ActiveRecord::Migration[7.1]
  def self.up
    add_column :data_apps, :data_app_sessions_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :data_apps, :data_app_sessions_count
  end
end
