# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogs::UpdateCatalog do
  let(:workspace) { create(:workspace) }
  let(:connector) { create(:connector, workspace:, connector_name: "Klaviyo", connector_type: "destination") }
  let(:existing_catalog) { create(:catalog, connector:, catalog: { "streams" => [] }) }

  context "with valid params" do
    let(:catalog_params) do
      {
        "name" => "Updated Catalog",
        "url" => "http://updated-example.com",
        "json_schema" => { "type" => "object" },
        "batch_support" => true,
        "batch_size" => 20,
        "request_method" => "PUT"
      }
    end

    it "updates the existing catalog" do
      result = described_class.call(
        connector:,
        catalog: existing_catalog,
        catalog_params:
      )

      expect(result.success?).to eq(true)
      expect(result.catalog.catalog["streams"].first).to include(catalog_params)
      expect(result.catalog.workspace_id).to eql(connector.workspace_id)
      expect(result.catalog.connector_id).to eql(connector.id)

      default_catalog = connector.pull_catalog
      expect(result.catalog.catalog["request_rate_limit"]).to eql(default_catalog[:request_rate_limit])
      expect(result.catalog.catalog["request_rate_limit_unit"]).to eql(default_catalog[:request_rate_limit_unit])
      expect(result.catalog.catalog["request_rate_concurrency"]).to eql(default_catalog[:request_rate_concurrency])
    end
  end

  context "with invalid params" do
    let(:catalog_params) do
      {
        "name" => "Updated Catalog",
        "url" => "http://updated-example.com",
        # Missing required json_schema
        "batch_support" => true,
        "batch_size" => 20,
        "request_method" => "PUT"
      }
    end

    it "fails to update the catalog" do
      result = described_class.call(
        connector:,
        catalog: existing_catalog,
        catalog_params:
      )

      expect(result.failure?).to eq(true)
      expect(result.error).to eq("json_schema must be present in catalog_params")
    end
  end

  context "when update operation fails" do
    let(:catalog_params) do
      {

        "name" => "Invalid Update",
        "url" => "http://invalid-update.com",
        "json_schema" => { "type" => "object" },
        "batch_support" => true,
        "batch_size" => 20,
        "request_method" => "PUT"
      }
    end

    before do
      allow_any_instance_of(Catalog).to receive(:update).and_return(false)
    end

    it "fails with an appropriate error" do
      result = described_class.call(
        connector:,
        catalog: existing_catalog,
        catalog_params:
      )

      expect(result.failure?).to eq(true)
    end
  end
end
