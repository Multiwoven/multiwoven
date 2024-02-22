# frozen_string_literal: true

FactoryBot.define do
  factory :sync_record do
    association :sync
    association :sync_run
    primary_key { Faker::Config.random }
    record { { gender: "male" } }
    action { "destination_insert" }
    fingerprint { Faker::Crypto.md5 }
  end
end
