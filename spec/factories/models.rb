# frozen_string_literal: true

FactoryBot.define do
  factory :model do
    association :connector
    association :workspace
    name { Faker::Name.name }
    query { Faker::Quote.yoda }
    query_type { "raw_sql" }
    primary_key { "TestPrimaryKey" }
  end
end
