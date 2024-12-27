# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlertChannel, type: :model do
  describe "associations" do
    it { should belong_to(:alert) }
  end

  describe "validations" do
    it { should validate_presence_of(:platform) }
  end

  describe "platform" do
    it "defines platform enum with specified values" do
      expect(AlertChannel.platforms).to eq({ "email" => 0, "slack" => 1 })
    end
  end
end
