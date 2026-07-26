# frozen_string_literal: true

class CreatePromptToWorkflowSessionEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :prompt_to_workflow_session_events do |t|
      t.references :prompt_to_workflow_session, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :prompt_to_workflow_session_events,
              %i[prompt_to_workflow_session_id sequence],
              unique: true,
              name: "idx_p2w_events_session_sequence"
  end
end
