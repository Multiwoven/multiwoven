class AddUniqueIndexToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_index :organizations, :name, unique: true
  end
end
