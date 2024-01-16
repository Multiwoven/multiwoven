class AddCursorFieldsToSync < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :primary_key, :string
    add_column :syncs, :cursor_field, :string
    add_column :syncs, :last_synced_cursor, :string
  end
end
