# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  validates :content, presence: true
  validates :visual_component_id, presence: true, if: :data_app_session?
  validates :workflow_id, presence: true, if: :workflow_session?

  counter_culture %i[visual_component data_app]
  # Using direct attribute check to avoid visibility issues with the model method
  counter_culture :session,
                  column_name: proc { |model|
                                 model.session_type == "Agents::WorkflowSession" ? "workflow_chat_messages_count" : nil
                               }

  belongs_to :workspace

  belongs_to :session, polymorphic: true
  belongs_to :visual_component, optional: true
  belongs_to :workflow, class_name: "Agents::Workflow", optional: true

  enum role: { user: 0, assistant: 1 }

  private

  def data_app_session?
    session_type == "DataAppSession"
  end

  def workflow_session?
    session_type == "Agents::WorkflowSession"
  end
end
