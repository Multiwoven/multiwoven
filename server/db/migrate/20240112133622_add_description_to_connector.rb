class AddDescriptionToConnector < ActiveRecord::Migration[7.1]
  def change
    add_column :connectors, :description, :string
  end
end
