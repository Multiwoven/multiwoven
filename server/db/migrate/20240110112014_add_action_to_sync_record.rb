class AddActionToSyncRecord < ActiveRecord::Migration[7.1]
  def change
    add_column :sync_records, :action, :integer
  end
end
