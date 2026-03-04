# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_session, class: "Agents::WorkflowSession" do
    session_id { SecureRandom.hex(10) }
    workflow
    workspace { workflow.workspace }
  end
end
