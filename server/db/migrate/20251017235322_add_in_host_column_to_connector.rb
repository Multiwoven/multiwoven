class AddInHostColumnToConnector < ActiveRecord::Migration[7.1]
  def up
    add_column :connectors, :in_host, :boolean, default: false
  end

  def down
    remove_column :connectors, :in_host
  end
end
