class RemoveModelIdFromFeedbacksAndMessageFeedbacks < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      remove_reference :feedbacks, :model, index: true
      remove_reference :message_feedbacks, :model, index: true
    end
  end
end
