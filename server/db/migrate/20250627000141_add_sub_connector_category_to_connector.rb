class AddSubConnectorCategoryToConnector < ActiveRecord::Migration[7.1]
  def change
    add_column :connectors, :connector_sub_category, :string, null: false, default: "database"
  end
end
