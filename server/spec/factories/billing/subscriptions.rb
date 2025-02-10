# frozen_string_literal: true

FactoryBot.define do
  factory :billing_subscription, class: "Billing::Subscription" do
    organization { nil }
<<<<<<< HEAD
    plan { nil }
=======
    billing_plan { nil }
>>>>>>> main
    status { 1 }
    data_app_sessions { 1 }
    feedback_count { 1 }
    rows_synced { 1 }
    addons_usage { {} }
  end
end
