# frozen_string_literal: true

# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  api_key    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :workspace do
    association :organization
    name { Faker::Name.name }
    slug { Faker::Beer.name }
    status { "active" }
    api_key { Faker::Config.random }

    after(:create) do |workspace|
      create(:workspace_user, workspace:, user: create(:user), role: create(:role, :admin))
    end
  end
end
