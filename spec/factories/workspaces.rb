# frozen_string_literal: true

FactoryBot.define do
  factory :workspace do
    name { Faker::Name.name }
    slug { Faker::Beer.name }
    status { "active" }
    api_key { Faker::Config.random }
    workspace_id { Faker::Config.random }
  end
end
