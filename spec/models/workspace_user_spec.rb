# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceUser, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:workspace) }
  end

  describe "validations" do
    it { should validate_inclusion_of(:role).in_array(%w[admin member viewer]) }

    it "should validate presence of associated user" do
      subject.user = nil
      expect(subject).to_not be_valid
    end

    it "should validate presence of associated workspace" do
      subject.workspace = nil
      expect(subject).to_not be_valid
    end
  end

  # Further methods and edge cases can be tested here.
end
