# frozen_string_literal: true

FactoryBot.define do
  factory :alert do
    association :workspace
    name { "Test alert" }
    alert_sync_success { false }
    alert_sync_failure { false }
    alert_row_failure { false }
    row_failure_threshold_percent { 50 }
  end
end
