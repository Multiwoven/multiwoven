class RemoveMetadataAndTimestampFromMessageFeedbacks < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :message_feedbacks, :metadata }
    safety_assured { remove_column :message_feedbacks, :timestamp }
  end
end
