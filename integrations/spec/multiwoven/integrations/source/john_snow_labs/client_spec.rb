# frozen_string_literal: true

require "spec_helper"

RSpec.describe Multiwoven::Integrations::Source::JohnSnowLabs::Client do
  subject(:client) { described_class.new }

  it "reuses the GenericOpenAI client and loads John Snow Labs' own config" do
    expect(described_class).to be < Multiwoven::Integrations::Source::GenericOpenAI::Client
    expect(client.meta_data[:data][:name]).to eq("JohnSnowLabs")
    expect(client.meta_data[:data][:managed_by_ais]).to be(true)
    expect(client.connector_spec.connection_specification[:title]).to eq("John Snow Labs")
    expect(client.connector_spec.connector_query_type).to eq("ai_ml")
  end

  it "ships a curated catalog rather than depending on OpenRouter" do
    expect(Multiwoven::Integrations::Core::OpenRouterCatalog).not_to receive(:fetch)
    expect(client.model_catalog.models.map(&:id)).to include("jsl-medm")
  end

  it "discovers John Snow Labs' own catalog.json" do
    catalog = client.discover(nil).catalog

    expect(catalog.request_rate_limit).to eq(600)
    expect(catalog.request_rate_limit_unit).to eq("minute")
    expect(catalog.request_rate_concurrency).to eq(10)
    expect(catalog.streams).to eq([])
  end
end
