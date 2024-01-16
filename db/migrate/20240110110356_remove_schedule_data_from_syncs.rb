class RemoveScheduleDataFromSyncs < ActiveRecord::Migration[7.1]
  def change
    remove_column :syncs, :schedule_data, :jsonb
  end
end
