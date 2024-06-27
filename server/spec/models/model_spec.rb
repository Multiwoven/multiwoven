# frozen_string_literal: true

# == Schema Information
#
# Table name: models
#
#  id           :bigint           not null, primary key
#  name         :string
#  workspace_id :integer
#  connector_id :integer
#  query        :text
#  query_type   :integer
#  primary_key  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "rails_helper"

RSpec.describe Model, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:connector) }
  end

  describe "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:query) }
    it { should have_many(:syncs).dependent(:destroy) }
  end

  describe "#to_protocol" do
    it "returns a protocol model with correct attributes" do
      model = Model.new(
        workspace_id: 1,
        connector_id: 1,
        name: "Test Model",
        query: "SELECT * FROM table",
        primary_key: "id",
        query_type: :raw_sql
      )
      protocol_model = model.to_protocol
      expect(protocol_model).to be_a(Multiwoven::Integrations::Protocol::Model)
      expect(protocol_model.name).to eq(model.name)
      expect(protocol_model.query).to eq(model.query)
      expect(protocol_model.query_type).to eq(model.query_type)
      expect(protocol_model.primary_key).to eq(model.primary_key)
      expect(model).to have_many(:syncs).dependent(:destroy)
    end
  end

  describe "#default_scope" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:model) { create_list(:model, 4, connector: source) }

    context "when a multiple models are created" do
      it "returns the model in descending order of updated_at" do
        expect(Model.all).to eq(model.sort_by(&:updated_at).reverse)
      end
    end

    context "when a model is updated" do
      it "returns the model in descending order of updated_at" do
        model.first.update(updated_at: DateTime.current + 1.week)
        model.last.update(updated_at: DateTime.current - 1.week)

        expect(Model.all).to eq(model.sort_by(&:updated_at).reverse)
      end
    end
  end

  describe "query_type" do
    it "defines query_type enum with specified values" do
      expect(Model.query_types).to eq({ "raw_sql" => 0, "dbt" => 1, "soql" => 2, "table_selector" => 3 })
    end
  end
end
