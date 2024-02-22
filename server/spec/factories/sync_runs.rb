# frozen_string_literal: true

FactoryBot.define do
  factory :sync_run do
    association :sync
    status { 1 }
    started_at { "2024-01-08 01:47:34" }
    finished_at { "2024-01-08 01:47:34" }
    total_rows { 1 }
    successful_rows { 1 }
    failed_rows { 1 }
    error { "MyText" }
  end
end
