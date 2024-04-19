class UpdateScheduleTypeInSyncs < ActiveRecord::Migration[7.1]
  def change
    Sync.where(schedule_type: 'automated').update_all(schedule_type: 'interval')
  end
end
