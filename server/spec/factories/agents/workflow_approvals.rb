# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_approval, class: "Agents::WorkflowApproval" do
    association :workflow_run, factory: :workflow_run
    association :workspace
    component_id { "hitl-#{SecureRandom.hex(4)}" }
    status { :pending }
    message { "Please review and approve this workflow step." }
    input_data { { "input_text" => "Sample input data" } }
    temporal_workflow_id { "workflow-#{SecureRandom.hex(8)}-dag-#{SecureRandom.hex(4)}" }
    temporal_run_id { SecureRandom.uuid }
    timeout_action { "reject" }

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
      resolved_at { Time.current }
      resolution_note { "Approved" }
    end

    trait :rejected do
      status { :rejected }
      resolved_at { Time.current }
      resolution_note { "Rejected" }
    end

    trait :timed_out do
      status { :timed_out }
      resolved_at { Time.current }
    end

    trait :with_timeout do
      timeout_at { 24.hours.from_now }
      timeout_action { "reject" }
    end

    trait :with_resolved_by do
      association :resolved_by, factory: :user
      resolved_at { Time.current }
    end
  end
end
