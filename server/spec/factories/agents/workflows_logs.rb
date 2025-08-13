# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_log, class: "Agents::WorkflowLog" do
    workflow_id { 1 }
    workflow_run_id { 1 }
    input { "{ \"text\" : \"Hello world\" }" }
    output { nil }
    logs { {} }

    created_at { Time.current }
    updated_at { Time.current }

    association :workspace
  end
end
