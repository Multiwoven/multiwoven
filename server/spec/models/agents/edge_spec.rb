# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Edge, type: :model do
  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:workspace) }
    it { should belong_to(:source_component).class_name("Agents::Component") }
    it { should belong_to(:target_component).class_name("Agents::Component") }
  end

  describe "validations" do
    it { should validate_presence_of(:source_handle) }
    it { should validate_presence_of(:target_handle) }
  end

  describe "attributes" do
    let(:edge) { create(:edge) }

    it "stores source_handle as JSON" do
      source_handle_data = { "field_name" => "message", "type" => "string" }
      edge.source_handle = source_handle_data
      edge.save!
      edge.reload
      expect(edge.source_handle).to eq(source_handle_data)
    end

    it "stores target_handle as JSON" do
      target_handle_data = { "field_name" => "message", "type" => "string" }
      edge.target_handle = target_handle_data
      edge.save!
      edge.reload
      expect(edge.target_handle).to eq(target_handle_data)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:edge)).to be_valid
    end

    it "creates valid associations" do
      edge = create(:edge)
      expect(edge.workflow).to be_present
      expect(edge.workspace).to be_present
      expect(edge.source_component).to be_present
      expect(edge.target_component).to be_present
    end
  end
end
