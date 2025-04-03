class CreateChatMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_messages do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :data_app_session, null: false, foreign_key: true
      t.references :visual_component, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :role, null: false

      t.timestamps
    end

    add_index :chat_messages, [:data_app_session_id, :created_at]
  end
end
