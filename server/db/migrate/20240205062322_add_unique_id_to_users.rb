class AddUniqueIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :unique_id, :string
    add_index :users, :unique_id
  end
end
