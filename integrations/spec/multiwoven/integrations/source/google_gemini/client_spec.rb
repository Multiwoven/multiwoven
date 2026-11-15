# frozen_string_literal: true

require "spec_helper"

RSpec.describe Multiwoven::Integrations::Source::GoogleGemini::Client do
  subject(:client) { described_class.new }

  before do
    allow(Multiwoven::Integrations::Core::OpenRouterCatalog).to receive(:fetch).and_return(
      Multiwoven::Integrations::Core::OpenRouterCatalog::Result.new(
        models_by_slug: {}, fetched_at: Time.now, source: "unavailable"
      )
    )
  end

  it "reuses the GenericOpenAI client and loads Gemini's own config" do
    expect(described_class).to be < Multiwoven::Integrations::Source::GenericOpenAI::Client
    expect(client.meta_data[:data][:name]).to eq("GoogleGemini")
    expect(client.meta_data[:data][:openrouter_slug]).to eq("google")
    expect(client.connector_spec.connection_specification[:title]).to eq("Google Gemini")
    expect(client.connector_spec.connector_query_type).to eq("ai_ml")
  end

  it "keeps curated embeddings when OpenRouter is down" do
    expect(client.curated_models.map { |model| model[:id] }).to include("text-embedding-004")
  end

  it "discovers Gemini's own catalog.json" do
    catalog = client.discover(nil).catalog

    expect(catalog.request_rate_limit).to eq(600)
    expect(catalog.request_rate_limit_unit).to eq("minute")
    expect(catalog.request_rate_concurrency).to eq(10)
    expect(catalog.streams).to eq([])
  end
end
