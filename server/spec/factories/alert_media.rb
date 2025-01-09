# frozen_string_literal: true

FactoryBot.define do
  factory :alert_medium do
    logo { nil }
    name { "Email" }
    platform { 0 }
  end
end
