# frozen_string_literal: true

FactoryBot.define do
  factory :catalog do
    association :workspace
    association :connector
    catalog do
      { "streams" => [
        { "name" => "profile", "json_schema" => {} },
        { "name" => "customer", "json_schema" => {} }
      ] }
    end
    catalog_hash { 1 }
  end
end
