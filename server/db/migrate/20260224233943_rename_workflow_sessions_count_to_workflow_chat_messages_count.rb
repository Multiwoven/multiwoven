class RenameWorkflowSessionsCountToWorkflowChatMessagesCount < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:workflow_sessions, :workflow_chat_messages_count)
      add_column :workflow_sessions, :workflow_chat_messages_count, :integer, null: false, default: 0
    end
    if column_exists?(:workflow_sessions, :workflow_sessions_count)
      remove_column :workflow_sessions, :workflow_sessions_count
    end
  end

  def down
    unless column_exists?(:workflow_sessions, :workflow_sessions_count)
      add_column :workflow_sessions, :workflow_sessions_count, :integer, null: false, default: 0
    end
    if column_exists?(:workflow_sessions, :workflow_chat_messages_count)
      remove_column :workflow_sessions, :workflow_chat_messages_count
    end
  end
end
