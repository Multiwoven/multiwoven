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

    it "memoizes the catalog so a second call does not refetch" do
      stub_upstream({ "anthropic" => [upstream_model] })

      client.model_catalog
      client.model_catalog

      expect(Multiwoven::Integrations::Core::OpenRouterCatalog).to have_received(:fetch).once
    end

    it "keeps upstream ids in the catalog" do
      stub_upstream({ "anthropic" => [{ id: "claude-sonnet-4.5", name: "Claude Sonnet 4.5", model_type: "llm" }] })

      expect(client.model_catalog.models.map(&:id)).to eq(["claude-sonnet-4.5"])
    end

    it "pins live catalog ids with model_id_overrides when present" do
      stub_upstream({ "anthropic" => [{ id: "claude-haiku-4.5", name: "Claude Haiku 4.5", model_type: "llm" }] })
      allow(client).to receive(:meta_data).and_return(
        {
          data: {
            openrouter_slug: "anthropic",
            model_id_overrides: { "claude-haiku-4.5" => "claude-haiku-4-5-20251001" }
          }
        }
      )

      expect(client.model_catalog.models.map(&:id)).to eq(["claude-haiku-4-5-20251001"])
    end

    it "still reports curated models when upstream is unavailable" do
      stub_upstream({})

      expect(client.model_catalog.models.map(&:id)).to eq(client.curated_models.map { |model| model[:id] })
    end

    it "omits Anthropic models below ANTHROPIC_EXCLUDE_MODELS" do
      stub_const("Multiwoven::Integrations::Core::Constants::ANTHROPIC_EXCLUDE_MODELS", "4.1")
      stub_upstream(
        {
          "anthropic" => [
            { id: "claude-opus-5", name: "Claude Opus 5", model_type: "llm",
              openrouter_id: "anthropic/claude-opus-5" },
            { id: "claude-3-haiku", name: "Claude 3 Haiku", model_type: "llm",
              openrouter_id: "anthropic/claude-3-haiku" },
            { id: "claude-sonnet-4", name: "Claude Sonnet 4", model_type: "llm",
              openrouter_id: "anthropic/claude-sonnet-4" },
            { id: "claude-opus-4.1", name: "Claude Opus 4.1", model_type: "llm",
              openrouter_id: "anthropic/claude-opus-4.1" },
            { id: "claude-opus-4-1", name: "Claude Opus 4.1 hyphenated", model_type: "llm",
              openrouter_id: "anthropic/claude-opus-4.1-hyphen" },
            { id: "claude-haiku-4-5-20251001", name: "Claude Haiku 4.5 dated", model_type: "llm",
              openrouter_id: "anthropic/claude-haiku-4.5-dated" },
            { id: "claude-sonnet-4-20250514", name: "Claude Sonnet 4 dated", model_type: "llm",
              openrouter_id: "anthropic/claude-sonnet-4-dated" },
            { id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet dated", model_type: "llm",
              openrouter_id: "anthropic/claude-3.5-sonnet-dated" }
          ]
        }
      )

      ids = client.model_catalog.models.map(&:id)

      expect(ids).to include("claude-opus-5", "claude-opus-4.1", "claude-opus-4-1",
                             "claude-haiku-4-5-20251001")
      expect(ids).not_to include("claude-3-haiku", "claude-sonnet-4", "claude-sonnet-4-20250514",
                                 "claude-3-5-sonnet-20241022")
    end
  end

  describe "OpenAI" do
    subject(:client) { Multiwoven::Integrations::Source::OpenAI::Client.new }

    it "keeps upstream ids and omits curated embeddings from the catalog" do
      stub_upstream(
        {
          "openai" => [
            { id: "gpt-4o", name: "GPT-4o", model_type: "llm", openrouter_id: "openai/gpt-4o" },
            { id: "gpt-5.1", name: "GPT-5.1", model_type: "llm", openrouter_id: "openai/gpt-5.1" }
          ]
        }
      )

      catalog_ids = client.model_catalog.models.map(&:id)
      expect(catalog_ids).to include("gpt-4o", "gpt-5.1")
      expect(catalog_ids).not_to include("text-embedding-3-large")
    end

    it "omits models listed in OPENAI_EXCLUDE_MODELS" do
      stub_const(
        "Multiwoven::Integrations::Core::Constants::OPENAI_EXCLUDE_MODELS",
        "gpt-4-turbo-preview,o3-mini-high,gpt-5.1-codex"
      )
      stub_upstream(
        {
          "openai" => [
            { id: "gpt-4o", name: "GPT-4o", model_type: "llm", openrouter_id: "openai/gpt-4o" },
            { id: "gpt-4-turbo-preview", name: "GPT-4 Turbo Preview", model_type: "llm",
              openrouter_id: "openai/gpt-4-turbo-preview" },
            { id: "o3-mini-high", name: "o3 Mini High", model_type: "llm",
              openrouter_id: "openai/o3-mini-high" },
            { id: "gpt-5.1-codex", name: "GPT-5.1 Codex", model_type: "llm",
              openrouter_id: "openai/gpt-5.1-codex" }
          ]
        }
      )

      ids = client.model_catalog.models.map(&:id)

      expect(ids).to include("gpt-4o")
      expect(ids).not_to include("gpt-4-turbo-preview", "o3-mini-high", "gpt-5.1-codex")
    end
  end

  describe "Google Gemini" do
    subject(:client) { Multiwoven::Integrations::Source::GoogleGemini::Client.new }

    it "omits models listed in GOOGLE_GEMINI_EXCLUDE_MODELS" do
      stub_const(
        "Multiwoven::Integrations::Core::Constants::GOOGLE_GEMINI_EXCLUDE_MODELS",
        "gemini-1.5-pro,gemini-1.0-pro"
      )
      stub_upstream(
        {
          "google" => [
            { id: "gemini-2.5-pro", name: "Gemini 2.5 Pro", model_type: "llm",
              openrouter_id: "google/gemini-2.5-pro" },
            { id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", model_type: "llm",
              openrouter_id: "google/gemini-1.5-pro" },
            { id: "gemini-1.0-pro", name: "Gemini 1.0 Pro", model_type: "llm",
              openrouter_id: "google/gemini-1.0-pro" }
          ]
        }
      )

      ids = client.model_catalog.models.map(&:id)

      expect(ids).to include("gemini-2.5-pro")
      expect(ids).not_to include("gemini-1.5-pro", "gemini-1.0-pro")
    end

    it "does not hand-curate models in models.json" do
      expect(client.curated_models).to eq([])
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

      expect(ids).to include("bolt-instruct-32b")
      expect(ids).not_to include("bolt-instruct-1b", "bolt-instruct-7b", "bolt-vision-9b", "bolt-embedding-large")
    end

    it "loads John Snow Labs curated models from models.json" do
      ids = Multiwoven::Integrations::Source::JohnSnowLabs::Client.new.model_catalog.models.map(&:id)

      expect(ids).to include("jsl-medm", "jsl-medical-embedding")
    end
  end

  describe "listing only what a connector can serve" do
    it "keeps embeddings where the endpoint is user supplied or model addressed" do
      {
        Multiwoven::Integrations::Source::AwsBedrockModel::Client => "amazon.titan-embed-text-v2:0",
        Multiwoven::Integrations::Source::WatsonxAi::Client => "ibm/slate-125m-english-rtrvr",
        Multiwoven::Integrations::Source::JohnSnowLabs::Client => "jsl-medical-embedding"
      }.each do |klass, embedding_id|
        expect(klass.new.model_catalog.models.map(&:id)).to include(embedding_id)
      end
    end

    it "drops image generation models, which have no payload path" do
      stub_upstream(
        {
          "openai" => [
            { id: "gpt-4o", name: "GPT-4o", model_type: "llm", type: "completion" },
            { id: "gpt-5-image", name: "GPT-5 Image", model_type: "vision", type: "image" }
          ]
        }
      )

      ids = Multiwoven::Integrations::Source::OpenAI::Client.new.model_catalog.models.map(&:id)

      expect(ids).to include("gpt-4o")
      expect(ids).not_to include("gpt-5-image")
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
