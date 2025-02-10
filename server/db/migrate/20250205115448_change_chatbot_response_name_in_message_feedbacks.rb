class ChangeChatbotResponseNameInMessageFeedbacks < ActiveRecord::Migration[7.1]
  def change
    safety_assured { rename_column :message_feedbacks, :chatbot_response, :chatbot_interaction }
  end
end
