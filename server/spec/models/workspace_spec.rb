# frozen_string_literal: true

# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  api_key    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe Workspace, type: :model do
  # Create a Workspace with an associated Organization before testing
  subject { create(:workspace) }

  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_inclusion_of(:status).in_array(%w[active inactive pending]) }
  end

  context "associations" do
    it { should have_many(:connectors).dependent(:nullify) }
    it { should have_many(:models).dependent(:nullify) }
    it { should have_many(:catalogs).dependent(:nullify) }
    it { should have_many(:syncs).dependent(:nullify) }
    it { should belong_to(:organization) }
  end

  context "before_validation callbacks" do
    it "generates slug, workspace_id, and status before validation on create" do
      workspace = described_class.new(name: "Example Workspace")
      workspace.valid?
      expect(workspace.slug).to be_present
      expect(workspace.status).to eq("pending")
    end

    it "generates api_key before validation on create" do
      workspace = described_class.new(name: "Example Workspace")
      workspace.valid?
      expect(workspace.api_key).to be_present
    end
  end
end
