class AddConnectorNameToConnector < ActiveRecord::Migration[7.1]
  def change
    add_column :connectors, :connector_name, :string
  end
end
