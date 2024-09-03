# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogs::CreateCatalog do
  let(:workspace) { create(:workspace) }
  let(:connector) { create(:connector, workspace:, connector_name: "Klaviyo", connector_type: "destination") }

  context "with valid params" do
    let(:catalog_params) do
      {
        "name" => "Test Catalog",
        "url" => "http://example.com",
        "json_schema" => { "type" => "object" },
        "batch_support" => true,
        "batch_size" => 10,
        "request_method" => "POST"
      }
    end

    it "creates catalog" do
      result = described_class.call(
        connector:,
        catalog_params:
      )
      expect(result.success?).to eq(true)
      expect(result.catalog.catalog["streams"].first).to eql(catalog_params)
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
        "name" => "Test Catalog",
        "url" => "http://example.com",
        "batch_support" => true,
        "batch_size" => 10,
        "request_method" => "POST"
      }
    end

    it "fails to create a connector" do
      result = described_class.call(workspace:, catalog_params:)
      expect(result.failure?).to eq(true)
    end
  end
end
