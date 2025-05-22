class AddChatMessagesCountToDataApps < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:data_apps, :chat_messages_count)
      add_column :data_apps, :chat_messages_count, :integer, null: false, default: 0
    end
  end
end
