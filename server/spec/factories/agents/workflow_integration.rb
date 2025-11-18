# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_integration, class: "Agents::WorkflowIntegration" do
    workspace
    workflow
    app_type { 0 }
    connection_configuration do
      {
        "client_id" => Faker::Alphanumeric.alphanumeric(number: 10),
        "client_secret" => Faker::Alphanumeric.alphanumeric(number: 10),
        "signing_signature" => Faker::Alphanumeric.alphanumeric(number: 10),
        "bot_token" => Faker::Alphanumeric.alphanumeric(number: 10)
      }
    end
    metadata do
      {
        "data_app_id" => Faker::Alphanumeric.alphanumeric(number: 10),
        "workflow_id" => Faker::Alphanumeric.alphanumeric(number: 10),
        "visual_component_id" => Faker::Alphanumeric.alphanumeric(number: 10)
      }
    end
  end
end
