# frozen_string_literal: true

require "spec_helper"

RSpec.describe Multiwoven::Integrations::Source::AzureOpenAI::Client do
  subject(:client) { described_class.new }

  it "reuses the GenericOpenAI client and loads Azure OpenAI's own config" do
    expect(described_class).to be < Multiwoven::Integrations::Source::GenericOpenAI::Client
    expect(client.meta_data[:data][:name]).to eq("AzureOpenAI")
    expect(client.connector_spec.connection_specification[:title]).to eq("Azure OpenAI")
    expect(client.connector_spec.connector_query_type).to eq("ai_ml")
  end

  it "sends Azure api-key instead of Bearer" do
    expect(client.send(:auth_headers, "secret")).to include("api-key" => "secret")
    expect(client.send(:auth_headers, "secret")).not_to have_key("Authorization")
  end

  it "does not depend on OpenRouter for deployment-specific models" do
    expect(Multiwoven::Integrations::Core::OpenRouterCatalog).not_to receive(:fetch)
    expect(client.model_catalog.models).to eq([])
  end

  it "discovers Azure OpenAI's own catalog.json" do
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
      expect(meta_data[:data][:icon]).to eq("https://res.cloudinary.com/dspflukeu/image/upload/v1789523456/Multiwoven/connectors/azure_open_ai/icon.svg")
    end
  end
end
