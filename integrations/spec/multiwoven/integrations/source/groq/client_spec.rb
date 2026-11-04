# frozen_string_literal: true

require "spec_helper"

RSpec.describe Multiwoven::Integrations::Source::Groq::Client do
  subject(:client) { described_class.new }

  it "reuses the GenericOpenAI client and loads Groq's own config" do
    expect(described_class).to be < Multiwoven::Integrations::Source::GenericOpenAI::Client
    expect(client.meta_data[:data][:name]).to eq("Groq")
    expect(client.connector_spec.connection_specification[:title]).to eq("Groq")
    expect(client.connector_spec.connector_query_type).to eq("ai_ml")
  end

  it "ships a curated GroqCloud catalog (OpenRouter has no matching groq slug)" do
    expect(client.meta_data.dig(:data, :openrouter_slug)).to be_nil
    expect(Multiwoven::Integrations::Core::OpenRouterCatalog).not_to receive(:fetch)

    ids = client.model_catalog.models.map(&:id)
    expect(ids).to include(
      "llama-3.1-8b-instant",
      "llama-3.3-70b-versatile",
      "openai/gpt-oss-120b",
      "openai/gpt-oss-20b",
      "groq/compound",
      "groq/compound-mini"
    )
  end

  it "discovers Groq's own catalog.json" do
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
      expect(meta_data[:data][:icon]).to eq("https://res.cloudinary.com/dspflukeu/image/upload/v1789523436/Multiwoven/connectors/groq/icon.svg")
    end
  end
end
