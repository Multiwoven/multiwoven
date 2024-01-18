# frozen_string_literal: true

# == Schema Information
#
# Table name: catalogs
#
#  id           :bigint           not null, primary key
#  workspace_id :integer
#  connector_id :integer
#  catalog      :jsonb
#  catalog_hash :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "rails_helper"

RSpec.describe Catalog, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:connector) }
  end

  describe "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_id) }
    it { should validate_presence_of(:catalog) }
    it { should validate_presence_of(:catalog_hash) }
  end

  describe "#find_stream_by_name" do
    let(:streams) do
      [
        { "name" => "profile", "other_attributes" => "value1" },
        { "name" => "customer", "other_attributes" => "value2" }
      ]
    end
    let(:catalog) { create(:catalog, catalog: { "streams" => streams }) }

    it "returns the correct stream when it exists" do
      stream = catalog.find_stream_by_name("profile")
      expect(stream).to eq({ "name" => "profile", "other_attributes" => "value1" })
    end

    it "returns nil when the stream does not exist" do
      stream = catalog.find_stream_by_name("non_existent")
      expect(stream).to be_nil
    end
  end
end
