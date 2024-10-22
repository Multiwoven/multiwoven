class CreateFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :feedbacks do |t|
      t.integer :workspace_id, null: false
      t.integer :data_app_id, null: false
      t.integer :visual_component_id, null: false
      t.integer :model_id, null: false
      t.integer :reaction, null: false
      t.text :feedback_content

      t.timestamps
    end
  end
end
