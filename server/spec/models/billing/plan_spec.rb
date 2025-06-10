# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Plan, type: :model do
  it "has a valid factory" do
    plan = Billing::Plan.new(name: "Basic Plan", status: :active, currency: :usd, interval: :monthly, addons: {})
    expect(plan).to be_valid
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should have_many(:subscriptions) }
  end

  describe "enums" do
    it "defines the correct status values" do
      expect(Billing::Plan.statuses).to eq({ "inactive" => 0, "active" => 1 })
    end

    it "defines the correct currency values" do
      expect(Billing::Plan.currencies).to eq({ "usd" => 0 })
    end

    it "defines the correct interval values" do
      expect(Billing::Plan.intervals).to eq({ "monthly" => 0, "year" => 1 })
    end
  end

  describe "addons serialization" do
    it "stores addons as a hash" do
      plan = Billing::Plan.create!(name: "Basic Plan", addons: { feature1: true, feature2: false })
      expect(plan.reload.addons).to be_a(Hash)
      expect(plan.addons).to eq({ "feature1" => true, "feature2" => false })
    end
  end
end
