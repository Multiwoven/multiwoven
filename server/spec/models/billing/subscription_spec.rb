# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Subscription, type: :model do
  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:plan) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_numericality_of(:data_app_sessions).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:feedback_count).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:rows_synced).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it "defines the correct status values" do
      expect(Billing::Subscription.statuses).to eq({
                                                     "trial" => 0,
                                                     "active" => 1,
                                                     "past_due" => 2,
                                                     "canceled" => 3,
                                                     "unpaid" => 4,
                                                     "paused" => 5
                                                   })
    end
  end

  describe "addons_usage serialization" do
    it "stores addons_usage as a JSON object" do
      subscription = Billing::Subscription.create!(
        organization: Organization.create!(name: "Test Org"),
        plan: Billing::Plan.create!(name: "Test Plan"),
        addons_usage: { "feature1" => true, "feature2" => false }
      )

      expect(subscription.reload.addons_usage).to be_a(Hash)
      expect(subscription.addons_usage).to eq({ "feature1" => true, "feature2" => false })
    end
  end
end
