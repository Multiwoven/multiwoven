# frozen_string_literal: true

FactoryBot.define do
  factory :connector do
    association :workspace
    connector_type { "destination" }
    configuration do
      { "public_api_key" => "config_v", "private_api_key" => "config_value_2" }
    end
    name { Faker::Name.name }
    connector_name { "klaviyo" }

    to_create { |instance| instance.save(validate: false) }
  end
end
