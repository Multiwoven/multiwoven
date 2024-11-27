# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomVisualComponentFile, type: :model do
  describe "associations" do
    it { should have_one_attached(:file) }
    it { should belong_to(:workspace) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      workspace = FactoryBot.create(:workspace)
      file_upload = FactoryBot.build(:custom_visual_component_file, workspace:)
      expect(file_upload).to be_valid
    end

    it "is not valid without a workspace" do
      file_upload = FactoryBot.build(:custom_visual_component_file, workspace: nil)
      expect(file_upload).to_not be_valid
    end
  end
end
