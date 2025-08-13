class MoveTitleFromChatMessagesToDataAppSession < ActiveRecord::Migration[7.1]
  def up
    if column_exists?(:chat_messages, :title)
      safety_assured { remove_column :chat_messages, :title }
    end

    unless column_exists?(:data_app_sessions, :title)
      add_column :data_app_sessions, :title, :string
    end
  end

  def down
    if column_exists?(:data_app_sessions, :title)
      safety_assured { remove_column :data_app_sessions, :title }
    end

    unless column_exists?(:chat_messages, :title)
      add_column :chat_messages, :title, :string
    end
  end
end
