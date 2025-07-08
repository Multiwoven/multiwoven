# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_run, class: "Agents::WorkflowRun" do
    association :workflow, factory: :workflow
    association :workspace
    status { "pending" }
    inputs { {} }
    outputs { {} }
    error_message { nil }
    temporal_workflow_id { nil }

    trait :pending do
      status { "pending" }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_inputs do
      inputs { { "key1" => "value1", "key2" => { "nested" => "value" } } }
    end

    trait :with_outputs do
      outputs { { "result" => "success", "data" => [1, 2, 3] } }
    end

    trait :with_error do
      error_message { "Something went wrong during execution" }
      status { "failed" }
    end

    trait :with_temporal_id do
      temporal_workflow_id { "workflow-#{SecureRandom.hex(8)}" }
    end

    trait :terminal do
      status { "completed" }
    end

    trait :active do
      status { "in_progress" }
    end
  end
end
