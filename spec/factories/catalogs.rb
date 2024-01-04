# frozen_string_literal: true

FactoryBot.define do
  factory :catalog do
    association :workspace
    association :connector
    catalog { Faker::Name.name }
    catalog_hash { 1 }
  end
end
