class AddWorkflowReferenceToChatMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :chat_messages, :workflow_id, algorithm: :concurrently
    add_foreign_key :chat_messages, :workflows, column: :workflow_id, validate: false
  end
end