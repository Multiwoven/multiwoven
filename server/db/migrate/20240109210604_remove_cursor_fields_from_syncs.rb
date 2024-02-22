class RemoveCursorFieldsFromSyncs < ActiveRecord::Migration[7.1]
  def change
    remove_column :syncs, :cursor_field, :string
    remove_column :syncs, :last_synced_cursor, :string
  end
end
