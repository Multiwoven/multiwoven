class AddStreamNameToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :stream_name, :string
  end
end
