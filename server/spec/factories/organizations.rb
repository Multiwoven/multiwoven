# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name { Faker::Company.unique.name }
    organization_logo_filename { "sample_file.svg" }

    after(:create) do |organization|
      plan = create(:billing_plan)
      create(:billing_subscription, organization:, plan:, status: 1)
      create(:eula, organization:, status: 1)
    end
  end
end
