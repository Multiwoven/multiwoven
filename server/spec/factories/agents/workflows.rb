# frozen_string_literal: true

FactoryBot.define do
  factory :workflow, class: "Agents::Workflow" do
    workspace
    name { "Test Workflow" }
    description { "A test workflow" }
    status { :draft }
    workflow_type { :runtime }
    trigger_type { :website_chatbot }
    configuration { { "api_key" => "sk-xxx", "endpoint" => "https://api.example.com" } }
  end
end
