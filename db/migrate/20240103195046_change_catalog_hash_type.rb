class ChangeCatalogHashType < ActiveRecord::Migration[7.1]
  def change
    change_column :catalogs, :catalog_hash, :string
  end
end
