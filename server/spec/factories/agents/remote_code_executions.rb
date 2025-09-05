# frozen_string_literal: true

FactoryBot.define do
  factory :remote_code_execution, class: "Agents::RemoteCodeExecution" do
    association :workflow_run
    association :workspace
    association :component, factory: :component

    provider { "aws_lambda" }
    mode { "workflow" }
    status { "success" }
    execution_time_ms { rand(100..5000) }
    memory_used_mb { rand(128..1024) }
    cpu_time_ms { rand(50..2000) }
    billed_duration_ms { rand(100..5000) }
    start_time { 1.hour.ago }
    end_time { 1.hour.ago + 2.seconds }
    invocation_id { SecureRandom.uuid }

    trait :failed do
      status { "error" }
      error_message { "Execution failed due to timeout" }
    end

    trait :test_mode do
      mode { "test" }
    end

    trait :with_stdout do
      stdout { "Hello World\nExecution completed successfully" }
    end
  end
end
