# frozen_string_literal: true

# == Schema Information
#
# Table name: connectors
#
#  id                      :bigint           not null, primary key
#  workspace_id            :integer
#  connector_type          :integer
#  connector_definition_id :integer
#  configuration           :jsonb
#  name                    :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  connector_name          :string
#
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
