# frozen_string_literal: true

FactoryBot.define do
  factory :sync do
    association :workspace
    association :model
    association :source, factory: :connector
    association :destination, factory: :connector
    configuration { { test: "Test" } }
    schedule_type { 1 }
    schedule_data { { test: "Test" } }
    status { 1 }
  end
end
