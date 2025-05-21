class AddMessageFeedbacksCountToDataApps < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:data_apps, :message_feedbacks_count)
      add_column :data_apps, :message_feedbacks_count, :integer, null: false, default: 0
    end
  end
end
