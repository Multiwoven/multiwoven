# frozen_string_literal: true

# == Schema Information
#
# Table name: catalogs
#
#  id           :bigint           not null, primary key
#  workspace_id :integer
#  connector_id :integer
#  catalog      :jsonb
#  catalog_hash :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :catalog do
    association :workspace
    association :connector
    catalog do
      {
        "streams" => [
          { "name" => "profile", "batch_support" => false, "batch_size" => 1, "json_schema" => {} },
          { "name" => "customer", "batch_support" => false, "batch_size" => 1, "json_schema" => {} },
          { "name" => "DatabricksModel", "batch_support" => false, "batch_size" => 1, "json_schema" =>
            {
              "input" => [{ "name" => "inputs.0", "type" => "string", "value" => "dynamic", "value_type" => "dynamic" },
                          { "name" => "inputs.0", "type" => "number", "value" => "9522", "value_type" => "static" }],
              "output" => [{ "name" => "predictions.col1.0", "type" => "string" },
                           { "name" => "predictions.col1.1", "type" => "number" }]
            } }
        ],
        "request_rate_limit" => 60,
        "request_rate_limit_unit" => "minute",
        "request_rate_concurrency" => 2
      }
    end
    catalog_hash { 1 }
  end
end
