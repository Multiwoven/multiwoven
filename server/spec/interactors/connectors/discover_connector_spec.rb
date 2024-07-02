# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::DiscoverConnector, type: :interactor do
  describe "#call" do
    let(:connector) { create(:connector) }
    let(:connector_client) { double("ConnectorClient") }
    let(:streams) { "stream_test_data" }

    context "when catalog is already present" do
      it "returns existing catalog" do
        catalog = create(:catalog, connector:)
        result = described_class.call(connector:)
        expect(result.catalog).to eq(catalog)
      end
    end

    context "refresh catalog even when catalog is present" do
      it "returns refreshed catalog" do
        catalog = create(:catalog, connector:)
        allow_any_instance_of(described_class).to receive(:streams).and_return(streams)
        result = described_class.call(connector:, refresh: true)
        expect(result.catalog).not_to eq(catalog)
      end
    end

    context "when catalog is not present" do
      it "create catalog" do
        expect(connector.catalog).to eq(nil)
        result = described_class.call(connector:)
        expect(connector.reload.catalog).not_to eq(nil)
        expect(result.success?).to eq(true)
      end
    end
  end
end
