# frozen_string_literal: true

# == Schema Information
#
# Table name: models
#
#  id           :bigint           not null, primary key
#  name         :string
#  workspace_id :integer
#  connector_id :integer
#  query        :text
#  query_type   :integer
#  primary_key  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
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
