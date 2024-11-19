class AddRenderingTypeToDataApps < ActiveRecord::Migration[7.1]
  def change
    add_column :data_apps, :rendering_type, :integer
  end
end
