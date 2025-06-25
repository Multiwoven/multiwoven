# frozen_string_literal: true

FactoryBot.define do
  factory :edge, class: "Agents::Edge" do
    id { SecureRandom.uuid }
    workflow
    workspace
    association :source_component, factory: :component
    association :target_component, factory: :component

    source_handle { { "field_name" => "message", "type" => "string" } }
    target_handle { { "field_name" => "message", "type" => "string" } }
  end
end
