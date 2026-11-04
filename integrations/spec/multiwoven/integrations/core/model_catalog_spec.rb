# frozen_string_literal: true

require "spec_helper"

RSpec.describe "connector model catalogs" do
  let(:upstream_model) { { id: "claude-opus-5", name: "Claude Opus 5", model_type: "llm" } }

  def stub_upstream(models_by_slug)
    allow(Multiwoven::Integrations::Core::OpenRouterCatalog).to receive(:fetch).and_return(
      Multiwoven::Integrations::Core::OpenRouterCatalog::Result.new(
        models_by_slug: models_by_slug, fetched_at: Time.now, source: "live"
      )
    )
  end

  it "builds a connector spec without reaching upstream" do
    Multiwoven::Integrations::Source::OpenAI::Client.new.connector_spec

    expect(
      a_request(:get, Multiwoven::Integrations::Core::OpenRouterCatalog::MODELS_URL)
    ).not_to have_been_made
  end

  describe "a provider declaring an openrouter_slug" do
    subject(:client) { Multiwoven::Integrations::Source::Anthropic::Client.new }

    it "reports upstream models on its spec" do
      stub_upstream({ "anthropic" => [upstream_model] })

      expect(client.model_catalog).to be_a(Multiwoven::Integrations::Protocol::ModelCatalog)
      expect(client.model_catalog.models.map(&:id)).to include("claude-opus-5")
    end

    it "pins a vendor-exact id when meta declares model_id_overrides" do
      stub_upstream({ "anthropic" => [upstream_model] })
      meta = client.meta_data
      meta[:data][:model_id_overrides] = { "claude-opus-5" => "claude-opus-5-20260101" }
      allow(client).to receive(:meta_data).and_return(meta)

      expect(client.model_catalog.models.map(&:id)).to eq(["claude-opus-5-20260101"])
    end

    it "still reports curated models when upstream is unavailable" do
      stub_upstream({})

      expect(client.model_catalog.models.map(&:id)).to eq(client.curated_models.map { |model| model[:id] })
    end
  end

  describe "a provider with only curated models" do
    subject(:client) { Multiwoven::Integrations::Source::AwsBedrockModel::Client.new }

    it "reports them without consulting upstream" do
      expect(Multiwoven::Integrations::Core::OpenRouterCatalog).not_to receive(:fetch)

      expect(client.model_catalog.models).not_to be_empty
    end

    it "reports them as protocol catalog entries" do
      expect(client.model_catalog.models.first).to be_a(Multiwoven::Integrations::Protocol::ModelCatalogEntry)
      expect(client.model_catalog.models.first.id).to be_present
    end

    it "loads Aisquared curated models from models.json" do
      ids = Multiwoven::Integrations::Source::Aisquared::Client.new.model_catalog.models.map(&:id)

      expect(ids).to include("bolt-instruct-32b", "bolt-embedding-large", "bolt-vision-9b")
    end

    it "loads John Snow Labs curated models from models.json" do
      ids = Multiwoven::Integrations::Source::JohnSnowLabs::Client.new.model_catalog.models.map(&:id)

      expect(ids).to include("jsl-medm", "jsl-medical-embedding")
    end
  end

  describe "models.json files" do
    it "does not park a catalog under //models, which curated_models ignores" do
      Dir[File.expand_path("../../../../lib/multiwoven/integrations/**/config/models.json", __dir__)].each do |path|
        data = JSON.parse(File.read(path))
        expect(data["//models"]).not_to be_a(Array),
                                        "#{path} stored models under //models; curated_models only reads ['models']"
      end
    end
  end

  describe "a connector with no model catalog" do
    it "reports an empty list" do
      client = Multiwoven::Integrations::Source::Postgresql::Client.new

      expect(client.model_catalog.models).to eq([])
    end
  end
end
