class AddNameToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :name, :string, null: false, default: ""
  end
end
