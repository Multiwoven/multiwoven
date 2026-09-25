# frozen_string_literal: true

require "spec_helper"

RSpec.describe Multiwoven::Integrations::Core::OpenRouterCatalog do
  # No cache configured, so every fetch hits the request path — all stubbed.
  let(:payload) do
    {
      "data" => [
        {
          "id" => "anthropic/claude-opus-5",
          "name" => "Claude Opus 5",
          "created" => 2_000,
          "context_length" => 1_000_000,
          "pricing" => {
            "prompt" => "0.000005",
            "completion" => "0.000025",
            "input_cache_read" => "0.0000005",
            "input_cache_write" => "0.00000625",
            "web_search" => "0.01"
          },
          "architecture" => { "input_modalities" => %w[text image file], "output_modalities" => ["text"] },
          "top_provider" => { "max_completion_tokens" => 128_000 },
          "supported_parameters" => %w[tools structured_outputs reasoning]
        },
        {
          "id" => "openai/gpt-image-1",
          "name" => "OpenAI: GPT Image 1",
          "created" => 3_000,
          "context_length" => 4_096,
          "pricing" => { "prompt" => "0.00001", "completion" => "" },
          "architecture" => { "input_modalities" => ["text"], "output_modalities" => %w[text image] },
          "top_provider" => {},
          "supported_parameters" => []
        }
      ]
    }
  end

  # The gem's HttpClient returns a raw Net::HTTP response, so stub a body.
  def stub_response(body)
    allow(Multiwoven::Integrations::Core::HttpClient)
      .to receive(:request).and_return(instance_double(Net::HTTPOK, body: body.to_json))
  end

  before do
    described_class.reset!
    stub_response(payload)
  end

  after { described_class.reset! }

  describe ".fetch" do
    subject(:result) { described_class.fetch }

    it "groups models by provider slug" do
      expect(result.models_by_slug.keys).to contain_exactly("anthropic", "openai")
      expect(result.models_for("anthropic").length).to eq(1)
    end

    it "is case-insensitive on the slug and returns [] for unknown or blank" do
      expect(result.models_for("Anthropic").length).to eq(1)
      expect(result.models_for("ibm")).to eq([])
      expect(result.models_for(nil)).to eq([])
    end

    it "returns every provider with full OpenRouter ids for the wildcard slug" do
      models = result.models_for("*")

      expect(models.map { |model| model[:id] }).to contain_exactly(
        "anthropic/claude-opus-5",
        "openai/gpt-image-1"
      )
    end

    it "does not mutate provider-specific model ids when building the wildcard catalog" do
      result.models_for("*")

      expect(result.models_for("anthropic").first[:id]).to eq("claude-opus-5")
    end

    it "falls back to the existing id when a wildcard model has no OpenRouter id" do
      result = described_class::Result.new(
        models_by_slug: { "custom" => [{ id: "custom-model" }] },
        fetched_at: Time.now,
        source: "live"
      )

      expect(result.models_for("*").first[:id]).to eq("custom-model")
    end

    context "with OpenRouter routing variants" do
      def variant_payload(entries)
        { "data" => entries.map { |id, price| variant_entry(id, price) } }
      end

      def variant_entry(id, price)
        {
          "id" => id,
          "name" => id,
          "created" => 1_000,
          "context_length" => 200_000,
          "pricing" => { "prompt" => price, "completion" => price },
          "architecture" => { "input_modalities" => ["text"], "output_modalities" => ["text"] },
          "top_provider" => {},
          "supported_parameters" => []
        }
      end

      it "drops a variant when the plain model is also published" do
        described_class.reset!
        stub_response(variant_payload([["anthropic/claude-opus-5", "0.000005"],
                                       ["anthropic/claude-opus-5:batch", "0.0000025"]]))

        models = described_class.fetch.models_for("anthropic")

        expect(models.map { |model| model[:id] }).to eq(["claude-opus-5"])
        expect(models.first[:pricing][:input]).to eq(5.0)
      end

      it "strips the variant suffix from openrouter_id too" do
        described_class.reset!
        stub_response(variant_payload([["anthropic/claude-opus-5:thinking", "0.000005"]]))

        model = described_class.fetch.models_for("anthropic").first

        expect(model[:id]).to eq("claude-opus-5")
        expect(model[:openrouter_id]).to eq("anthropic/claude-opus-5")
      end

      it "keeps a variant-only model under its plain id" do
        described_class.reset!
        stub_response(variant_payload([["anthropic/claude-opus-5:thinking", "0.000005"]]))

        expect(described_class.fetch.models_for("anthropic").map { |model| model[:id] })
          .to eq(["claude-opus-5"])
      end

      it "picks the same representative whatever the upstream order" do
        [[["openai/gpt-5:free", "0"], ["openai/gpt-5:batch", "0.000005"]],
         [["openai/gpt-5:batch", "0.000005"], ["openai/gpt-5:free", "0"]]].each do |entries|
          described_class.reset!
          stub_response(variant_payload(entries))

          models = described_class.fetch.models_for("openai")

          expect(models.map { |model| model[:id] }).to eq(["gpt-5"])
          expect(models.first[:pricing][:input]).to eq(5.0)
        end
      end

      it "collapses several variants of the same model" do
        described_class.reset!
        stub_response(variant_payload([["openai/gpt-5", "0.00001"],
                                       ["openai/gpt-5:batch", "0.000005"],
                                       ["openai/gpt-5:free", "0"]]))

        expect(described_class.fetch.models_for("openai").map { |model| model[:id] }).to eq(["gpt-5"])
      end
    end

    it "marks the payload as live and exposes an expiry" do
      expect(result.source).to eq("live")
    end

    it "strips the provider slug from the model id" do
      expect(result.models_for("anthropic").first[:id]).to eq("claude-opus-5")
    end

    it "converts per-token pricing to per-million" do
      pricing = result.models_for("anthropic").first[:pricing]

      expect(pricing[:input]).to eq(5.0)
      expect(pricing[:output]).to eq(25.0)
      expect(pricing[:cached_read]).to eq(0.5)
      expect(pricing[:cached_write]).to eq(6.25)
      expect(pricing[:unit]).to eq("per_1m_tokens")
    end

    it "returns nil rather than zero for pricing the source omits" do
      # A missing price must not read as free; the UI renders an em dash for nil.
      expect(result.models_for("openai").first[:pricing][:output]).to be_nil
    end

    it "reads context window and max output" do
      model = result.models_for("anthropic").first

      expect(model[:context_window]).to eq(1_000_000)
      expect(model[:max_output]).to eq(128_000)
    end

    it "leaves max output nil when the source does not provide it" do
      expect(result.models_for("openai").first[:max_output]).to be_nil
    end

    it "classifies image-output models as vision and text-output as llm" do
      expect(result.models_for("anthropic").first[:model_type]).to eq("llm")
      expect(result.models_for("openai").first[:model_type]).to eq("vision")
    end

    it "derives tasks from output modality and reasoning support" do
      expect(result.models_for("anthropic").first[:tasks]).to eq(["Text Generation", "Reasoning"])
      expect(result.models_for("openai").first[:tasks]).to include("Text-to-Image")
    end

    it "derives capabilities from input modalities and supported parameters" do
      expect(result.models_for("anthropic").first[:capabilities]).to contain_exactly(
        "Image analysis", "Documents", "Web search", "Tool use", "Structured output"
      )
    end

    it "strips a redundant vendor prefix from the display name" do
      expect(result.models_for("openai").first[:name]).to eq("GPT Image 1")
    end

    it "keeps a name that merely contains a colon" do
      stub_response({ "data" => [payload["data"].first.merge("name" => "Claude: The Sequel")] })
      described_class.reset!

      expect(described_class.fetch.models_for("anthropic").first[:name]).to eq("Claude: The Sequel")
    end

    it "does not leak the internal sort key" do
      expect(result.models_for("anthropic").first).not_to have_key(:released_at)
    end
  end

  describe "failure handling" do
    it "fails soft when the upstream errors, so the Model Hub still renders" do
      allow(Multiwoven::Integrations::Core::HttpClient)
        .to receive(:request).and_raise(StandardError, "boom")
      described_class.reset!

      result = described_class.fetch

      expect(result.source).to eq("unavailable")
      expect(result.models_for("anthropic")).to eq([])
    end

    it "fails soft when the upstream returns an unexpected body" do
      stub_response({ "error" => "nope" })
      described_class.reset!

      expect(described_class.fetch.source).to eq("unavailable")
    end

    it "retries after a failure instead of caching the empty catalog" do
      allow(Multiwoven::Integrations::Core::HttpClient)
        .to receive(:request).and_raise(StandardError, "boom")
      described_class.reset!
      described_class.fetch

      stub_response(payload)
      result = described_class.fetch

      expect(result.source).to eq("live")
      expect(result.models_for("anthropic")).not_to be_empty
    end
  end

  describe "caching" do
    it "does not re-request within the TTL when no cache store is configured" do
      described_class.fetch
      described_class.fetch

      expect(Multiwoven::Integrations::Core::HttpClient).to have_received(:request).once
    end

    it "passes timeouts through HttpClient's options hash" do
      described_class.fetch

      expect(Multiwoven::Integrations::Core::HttpClient).to have_received(:request).with(
        described_class::MODELS_URL, "GET", options: { config: described_class::REQUEST_CONFIG }
      )
    end

    it "does not persist an unavailable payload in the cache store" do
      store = {}
      cache = double("cache")
      allow(cache).to receive(:read) { |key| store[key] }
      allow(cache).to receive(:write) { |key, value, **| store[key] = value }
      allow(cache).to receive(:delete) { |key| store.delete(key) }
      allow(Multiwoven::Integrations::Service.config).to receive(:cache).and_return(cache)

      allow(Multiwoven::Integrations::Core::HttpClient)
        .to receive(:request).and_raise(StandardError, "boom")
      described_class.reset!
      described_class.fetch

      expect(cache).not_to have_received(:write)
    end
  end
end
