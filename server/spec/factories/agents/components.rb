# frozen_string_literal: true

FactoryBot.define do
  factory :component, class: "Agents::Component" do
    id { SecureRandom.uuid }
    workflow
    workspace
    name { "Test Component" }
    component_type { :chat_input }
    configuration { { "key" => "value" } }
    position { { "x" => 100, "y" => 100 } }
  end
end
