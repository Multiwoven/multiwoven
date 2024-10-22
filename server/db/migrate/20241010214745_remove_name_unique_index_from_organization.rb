class RemoveNameUniqueIndexFromOrganization < ActiveRecord::Migration[7.1]
  def change
    remove_index :organizations, :name
  end
end
