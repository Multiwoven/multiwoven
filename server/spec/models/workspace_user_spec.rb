# frozen_string_literal: true

# == Schema Information
#
# Table name: workspace_users
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  workspace_id :bigint
#  role         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "rails_helper"

RSpec.describe WorkspaceUser, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:workspace) }
    it { should belong_to(:role) }
  end

  describe "validations" do
    it "should validate presence of associated user" do
      subject.user = nil
      expect(subject).to_not be_valid
    end

    it "should validate presence of associated workspace" do
      subject.workspace = nil
      expect(subject).to_not be_valid
    end

    it "should validate presence of associated role" do
      subject.role = nil
      expect(subject).to_not be_valid
    end
  end

  # Further methods and edge cases can be tested here.
end
