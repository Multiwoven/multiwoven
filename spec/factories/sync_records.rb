# frozen_string_literal: true

FactoryBot.define do
  factory :sync_record do
    association :sync
    association :sync_run
    record { "" }
    fingerprint { "MyString" }
  end
end
