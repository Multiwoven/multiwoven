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
    it { should have_many(:syncs).dependent(:destroy) }
    it { should have_many(:visual_components).dependent(:destroy) }
  end

  describe "validations" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end

    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_id) }
    it { should validate_presence_of(:name) }

    context "when query_type requires query" do
      it "validates presence of query" do
        model = Model.new(
          name: "test_model",
          query_type: :raw_sql, connector_id: source.id,
          workspace_id: source.workspace_id
        )
        model.query = nil
        expect(model).not_to be_valid
        expect(model.errors[:query]).to include("can't be blank")
      end
    end

    context "when query_type does not require query" do
      it "does not validate presence of query" do
        model = Model.new(
          name: "test_model",
          query_type: :ai_ml, connector_id: source.id,
          workspace_id: source.workspace_id,
          configuration: { "field1" => "value1" }
        )
        model.query = nil
        expect(model).to be_valid
      end
    end

    context "when query_type requires configuration" do
      it "validates presence of configuration" do
        model = Model.new(
          name: "test_model",
          query_type: :ai_ml, connector_id: source.id,
          workspace_id: source.workspace_id
        )
        model.configuration = nil
        expect(model).not_to be_valid
      end
    end

    context "when query_type does not require configuration" do
      it "does not validate presence of configuration" do
        model = Model.new(
          name: "test_model",
          query_type: :raw_sql, connector_id: source.id,
          workspace_id: source.workspace_id, query: "test_query"
        )
        model.configuration = nil
        expect(model).to be_valid
      end
    end
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
    end
  end

  describe "#default_scope" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:model) { create_list(:model, 4, connector: source) }

    context "when multiple models are created" do
      it "returns the models in descending order of updated_at" do
        expect(Model.all).to eq(model.sort_by(&:updated_at).reverse)
      end
    end

    context "when a model is updated" do
      it "returns the models in descending order of updated_at" do
        model.first.update(updated_at: DateTime.current + 1.week)
        model.last.update(updated_at: DateTime.current - 1.week)

        expect(Model.all).to eq(model.sort_by(&:updated_at).reverse)
      end
    end
  end

  describe "query_type" do
    it "defines query_type enum with specified values" do
      expect(Model.query_types).to eq({ "raw_sql" => 0, "dbt" => 1, "soql" => 2, "table_selector" => 3, "ai_ml" => 4 })
    end
  end

  describe "scopes" do
    let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
    let!(:raw_sql_model) { create(:model, query_type: :raw_sql, connector: source) }
    let!(:dbt_model) { create(:model, query_type: :dbt, connector: source) }
    let!(:soql_model) { create(:model, query_type: :soql, connector: source) }
    let!(:table_selector_model) { create(:model, query_type: :table_selector, connector: source) }
    let!(:ai_ml_model) { create(:model, query_type: :ai_ml, connector: source, configuration: { test: "value" }) }

    describe ".data" do
      it "returns models with query_type in [raw_sql, dbt, soql, table_selector]" do
        data_models = Model.data
        expect(data_models).to include(raw_sql_model, dbt_model, soql_model, table_selector_model)
        expect(data_models).not_to include(ai_ml_model)
      end
    end

    describe ".ai_ml" do
      it "returns models with query_type equal to ai_ml" do
        ai_ml_models = Model.ai_ml
        expect(ai_ml_models).to include(ai_ml_model)
        expect(ai_ml_models).not_to include(raw_sql_model, dbt_model, soql_model, table_selector_model)
      end
    end
  end
end
