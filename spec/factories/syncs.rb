# frozen_string_literal: true

FactoryBot.define do
  factory :sync do
    association :workspace
    association :model
    association :source, factory: :connector
    association :destination, factory: :connector
    configuration { { test: "Test" } }
    schedule_type { 1 }
    sync_interval { 1 }
    stream_name { "profile" }
    sync_interval_unit { "hours" }
    status { 1 }
  end
end
