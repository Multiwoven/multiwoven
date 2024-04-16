class AddCursorFieldsToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :cursor_field, :string
    add_column :syncs, :current_cursor_field, :string
  end
end
