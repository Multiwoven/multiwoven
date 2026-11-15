# frozen_string_literal: true

class AddCurrentTurnToPromptToWorkflowSessions < ActiveRecord::Migration[7.1]
  def change
    return if column_exists?(:prompt_to_workflow_sessions, :current_turn)

    add_column :prompt_to_workflow_sessions, :current_turn, :integer, null: false, default: 0
  end
end
