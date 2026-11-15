# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name { Faker::Company.unique.name }
    organization_logo_filename { "sample_file.svg" }

    after(:create) do |organization|
<<<<<<< HEAD
      plan = create(:billing_plan)
      create(:billing_subscription, organization:, plan:, status: 1)
      create(:eula, organization:, status: 1)
=======
      next unless organization.persisted? && organization.valid?

      # Only create subscription if one doesn't already exist (data migrations might have created one)
      unless organization.subscriptions.exists?
        plan = create(:billing_plan)
        create(:billing_subscription, organization:, plan:, status: 1)
      end
      create(:eula, organization:, status: 1) unless organization.eulas.exists?
>>>>>>> 9eb4341c9 (feat(CE): add app gen models (#1695))
    end
  end
end
