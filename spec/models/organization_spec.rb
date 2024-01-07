# frozen_string_literal: true

# spec/models/organization_spec.rb

require "rails_helper"

RSpec.describe Organization, type: :model do
  # Test for valid factory
  it "has a valid factory" do
    expect(build(:organization)).to be_valid
  end

  # Test validations
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    # Add other validations here
  end

  # Test associations
  describe "associations" do
    it { should have_many(:workspaces).dependent(:destroy) }
    # Add other associations here
  end
end
