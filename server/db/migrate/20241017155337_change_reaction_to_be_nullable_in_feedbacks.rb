class ChangeReactionToBeNullableInFeedbacks < ActiveRecord::Migration[7.1]
  def change
    #text input reaction not required
    safety_assured do
      change_column :feedbacks, :reaction, :integer, null: true
    end
  end
end
