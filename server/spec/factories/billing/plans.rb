# frozen_string_literal: true

FactoryBot.define do
  factory :billing_plan, class: "Billing::Plan" do
    name { "MyString" }
    status { 0 }
    amount { 1.5 }
    currency { 0 }
    interval { 0 }
    max_data_app_sessions { 1 }
    max_feedback_count { 1 }
    max_rows_synced { 1 }
    addons { "MyText" }
  end
end
