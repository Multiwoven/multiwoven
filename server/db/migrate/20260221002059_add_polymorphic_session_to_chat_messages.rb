# frozen_string_literal: true

class AddPolymorphicSessionToChatMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Remove FK so we can rename column to polymorphic session_id
    safety_assured do
      remove_foreign_key :chat_messages, :data_app_sessions, if_exists: true
    end

    # Rename data_app_session_id to session_id
    safety_assured do
      if column_exists?(:chat_messages, :data_app_session_id)
        rename_column :chat_messages, :data_app_session_id, :session_id
      end
    end

    # Add session_type column for polymorphic relationship
    unless column_exists?(:chat_messages, :session_type)
      add_column :chat_messages, :session_type, :string
    end

    # Add workflow_id column for workflow sessions
    unless column_exists?(:chat_messages, :workflow_id)
      add_column :chat_messages, :workflow_id, :uuid, null: true
    end

    # Add index for session_type and session_id for polymorphic relationship
    add_index :chat_messages, [:session_type, :session_id], algorithm: :concurrently

    # Update session_type to 'DataAppSession' for data app sessions
    safety_assured do
      execute <<~SQL
        UPDATE chat_messages
        SET session_type = 'DataAppSession'
        WHERE visual_component_id IS NOT NULL
      SQL
    end

    # Allow visual_component_id to be null
    safety_assured do
      change_column_null :chat_messages, :visual_component_id, true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end