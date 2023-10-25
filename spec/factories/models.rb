# frozen_string_literal: true

FactoryBot.define do
  factory :model do
    name { "MyString" }
    workspace_id { 1 }
    connector_id { 1 }
    query { "MyText" }
    query_type { 1 }
    primary_key { "MyString" }
  end
end
