# frozen_string_literal: true

require "spec_helper"

RSpec.describe Multiwoven::Integrations::Source::Xai::Client do
  subject(:client) { described_class.new }

  it "reuses the GenericOpenAI client and loads xAI's own config" do
    expect(described_class).to be < Multiwoven::Integrations::Source::GenericOpenAI::Client
    expect(client.meta_data[:data][:name]).to eq("Xai")
    expect(client.connector_spec.connection_specification[:title]).to eq("xAI")
    expect(client.connector_spec.connector_query_type).to eq("ai_ml")
  end

  it "loads xAI models from OpenRouter's live catalog" do
    catalog = instance_double(Multiwoven::Integrations::Core::OpenRouterCatalog::Result)
    expect(Multiwoven::Integrations::Core::OpenRouterCatalog).to receive(:fetch).and_return(catalog)
    expect(catalog).to receive(:models_for).with("x-ai").and_return([])

    expect(client.model_catalog.models).to eq([])
  end

  it "discovers xAI's own catalog.json" do
    catalog = client.discover(nil).catalog

    expect(catalog.request_rate_limit).to eq(600)
    expect(catalog.request_rate_limit_unit).to eq("minute")
    expect(catalog.request_rate_concurrency).to eq(10)
    expect(catalog.streams).to eq([])
  end

  describe "#meta_data" do
    it "returns the correct meta data" do
      meta_data = client.send(:meta_data)
      meta_name = client.class.to_s.split("::")[-2]
      expect(meta_data).to be_a(Hash)
      expect(meta_data[:data][:name]).to eq(meta_name)
      expect(meta_data[:data][:connector_type]).to eq("source")
      expect(meta_data[:data][:icon]).to eq("https://res.cloudinary.com/dspflukeu/image/upload/v1789523733/Multiwoven/connectors/xai/icon.svg")
    end
  end
end
