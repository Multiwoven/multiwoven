class AddTitleToChatMessages < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:chat_messages, :title)
      add_column :chat_messages, :title, :string
    end
  end

  def down
    if column_exists?(:chat_messages, :title)
      remove_column :chat_messages, :title
    end
  end
end
