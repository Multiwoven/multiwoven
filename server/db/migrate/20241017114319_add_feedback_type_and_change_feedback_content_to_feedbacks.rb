class AddFeedbackTypeAndChangeFeedbackContentToFeedbacks < ActiveRecord::Migration[7.1]
  def up
    #safety_assured because feedback_content is not utilized
    safety_assured do
      change_column :feedbacks, :feedback_content, :json, using: 'feedback_content::json'
    end

    add_column :feedbacks, :feedback_type, :integer, null: false, default: 0
  end

  def down
    safety_assured do
      change_column :feedbacks, :feedback_content, :text, using: 'feedback_content::text'
    end

    remove_column :feedbacks, :feedback_type
  end
end
