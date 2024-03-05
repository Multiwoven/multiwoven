class AddDiscardedAtToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :discarded_at, :datetime
    add_index :syncs, :discarded_at
  end
end
