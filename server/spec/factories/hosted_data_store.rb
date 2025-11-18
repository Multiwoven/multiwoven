# frozen_string_literal: true

FactoryBot.define do
  factory :hosted_data_store do
    association :workspace
    association :source_connector
    association :destination_connector
    name { "My Hosted Data Store" }
    database_type { 0 }
    description { "My Hosted Data Store Description" }
    state { 0 }
    template_id { "vector_store_hosted_connector" }
  end
end
