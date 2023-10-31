# frozen_string_literal: true

FactoryBot.define do
  factory :connector_definition do
    connector_type { 1 }
    spec { { test: "test" } }
    source_type { 1 }
    meta_data { { test: "test" } }
  end
end
