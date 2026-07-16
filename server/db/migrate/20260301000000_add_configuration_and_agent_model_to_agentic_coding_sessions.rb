# frozen_string_literal: true

class AddConfigurationAndAgentModelToAgenticCodingSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :agentic_coding_sessions, :configuration, :jsonb, default: {}
    add_column :agentic_coding_sessions, :agent_model, :string
  end
end
