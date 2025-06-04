# frozen_string_literal: true

FactoryBot.define do
  factory :workflow, class: "Agents::Workflow" do
    workspace
    name { "Test Workflow" }
    description { "A test workflow" }
    status { :draft }
    trigger_type { :interactive }
    configuration { { "api_key" => "sk-xxx", "endpoint" => "https://api.example.com" } }
  end
end
