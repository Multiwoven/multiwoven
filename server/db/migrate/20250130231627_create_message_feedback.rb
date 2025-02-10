class CreateMessageFeedback < ActiveRecord::Migration[7.1]
  def change
    create_table :message_feedbacks do |t|
      t.integer :workspace_id, null: false
      t.integer :data_app_id, null: false
      t.integer :visual_component_id, null: false
      t.integer :model_id, null: false
      t.integer :reaction
      t.string :feedback_content
      t.integer :feedback_type, default: 0, null: false
      t.json :chatbot_response, null: false
      t.jsonb :additional_remark
      t.datetime :timestamp
      t.json :metadata

      t.timestamps
    end
  end
end
