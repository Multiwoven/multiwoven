# frozen_string_literal: true

FactoryBot.define do
  factory :hosted_data_store_table do
    association :hosted_data_store
    association :source_connector
    association :destination_connector
    name { "My Hosted Data Store Table" }
    column_count { 10 }
    row_count { 100 }
    size { 1000 }
    sync_enabled { 0 }
    table_schema do
      {
        "columns" => [{ "name" => "id", "type" => "integer" }, { "name" => "name", "type" => "string" }],
        "rows" => [{ "id" => 1, "name" => "John Doe" }]
      }
    end
  end
end
