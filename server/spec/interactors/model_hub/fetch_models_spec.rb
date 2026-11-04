# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModelHub::FetchModels, type: :interactor do
  let(:live_model) do
    {
      id: "claude-opus-5",
      openrouter_id: "anthropic/claude-opus-5",
      name: "Claude Opus 5",
      model_type: "llm",
      type: "completion",
      tasks: ["Text Generation", "Reasoning"],
      capabilities: ["Tool use"],
      context_window: 1_000_000,
      max_output: 128_000,
      pricing: { input: 5.0, output: 25.0, cached_read: 0.5, cached_write: 6.25, unit: "per_1m_tokens" },
      availability: "available",
      unavailable_reason: nil
    }
  end

  def stub_catalog(models_by_slug, source: "live")
    allow(Multiwoven::Integrations::Core::OpenRouterCatalog).to receive(:fetch).and_return(
      Multiwoven::Integrations::Core::OpenRouterCatalog::Result.new(
        models_by_slug:, fetched_at: Time.current, source:
      )
    )
  end

  describe "#call" do
    context "when the live source is available" do
      before { stub_catalog({ "anthropic" => [live_model] }) }

      it "includes live models for providers declaring an openrouter_slug" do
        models = described_class.call.models
        anthropic = models.select { |m| m[:provider_name] == "Anthropic" }

        expect(anthropic.map { |m| m[:id] }).to include("claude-opus-5")
        expect(anthropic.first[:context_window]).to eq(1_000_000)
      end

      it "denormalizes the provider onto live models" do
        model = described_class.call.models.find { |m| m[:id] == "claude-opus-5" }

        expect(model[:provider_title]).to eq("Anthropic")
        expect(model[:provider_type]).to eq("third_party")
      end

      it "still returns curated models for providers with no live source" do
        models = described_class.call.models

        expect(models.map { |m| m[:id] }).to include("ibm/granite-3-8b-instruct")
      end

      it "filters live models by task" do
        models = described_class.call(task: "Reasoning").models

        expect(models.map { |m| m[:id] }).to include("claude-opus-5")
      end

      it "filters by model_type" do
        models = described_class.call(model_type: "llm").models

        expect(models).to be_present
        expect(models.map { |m| m[:model_type] }.uniq).to eq(["llm"])
      end

      it "filters by provider name" do
        models = described_class.call(provider: "Anthropic").models

        expect(models.map { |m| m[:provider_name] }.uniq).to eq(["Anthropic"])
      end

      it "does not leak the internal ordering key" do
        expect(described_class.call.models.first).not_to have_key(:catalog_position)
      end
    end

    context "when a provider declares no models on its spec" do
      it "contributes nothing" do
        stub_catalog({})

        expect(described_class.call.models.map { |m| m[:provider_name] })
          .not_to include("AwsSagemakerModel")
      end
    end

    context "search" do
      before { stub_catalog({ "anthropic" => [live_model] }) }

      it "matches on display name, case-insensitively" do
        expect(described_class.call(q: "claude opus").models.map { |m| m[:id] })
          .to eq(["claude-opus-5", "anthropic/claude-opus-5"])
      end

      it "matches on the model id a user would paste" do
        expect(described_class.call(q: "slate-125m").models.map { |m| m[:id] })
          .to eq(["ibm/slate-125m-english-rtrvr"])
      end

      it "matches on provider, so a provider name finds all of its models" do
        expect(described_class.call(q: "watsonx").models.map { |m| m[:provider_name] }.uniq)
          .to eq(["WatsonxAi"])
      end

      it "matches a vendor named inside another provider's model, not just its own" do
        providers = described_class.call(q: "anthropic").models.map { |m| m[:provider_name] }.uniq

        expect(providers).to include("Anthropic", "AwsBedrockModel")
      end

      it "returns an empty list rather than everything when nothing matches" do
        result = described_class.call(q: "no-such-model-xyz")

        expect(result.models).to be_empty
        expect(result.meta[:total_count]).to eq(0)
      end
    end

    context "pagination" do
      before { stub_catalog({}) }

      it "defaults to the first page when pagination params are omitted" do
        result = described_class.call

        expect(result.meta[:page]).to eq(1)
        expect(result.meta[:per_page]).to eq(20)
        expect(result.models.size).to eq([result.meta[:total_count], 20].min)
        expect(result.links[:prev]).to be_nil
        expect(result.links[:next]).to be_nil if result.meta[:total_count] <= 20
      end

      it "defaults page to 1 when only per_page is provided" do
        result = described_class.call(per_page: 3)

        expect(result.meta[:page]).to eq(1)
        expect(result.meta[:per_page]).to eq(3)
        expect(result.models.size).to eq(3)
      end

      it "defaults per_page to 20 when only page is provided" do
        result = described_class.call(page: 1)

        expect(result.meta[:page]).to eq(1)
        expect(result.meta[:per_page]).to eq(20)
      end

      it "slices to the requested page and reports the full count" do
        all = described_class.call(per_page: 500).models
        result = described_class.call(page: 2, per_page: 3)

        expect(result.models.map { |m| m[:id] }).to eq(all[3, 3].map { |m| m[:id] })
        expect(result.meta[:total_count]).to eq(all.size)
        expect(result.links[:prev]).to eq(1)
      end

      it "has no next link on the last page" do
        total = described_class.call(per_page: 500).meta[:total_count]
        last = (total.to_f / 5).ceil

        expect(described_class.call(page: last, per_page: 5).links[:next]).to be_nil
      end

      it "returns an empty page past the end instead of erroring" do
        expect(described_class.call(page: 999, per_page: 10).models).to eq([])
      end
    end

    context "when the live source is unavailable" do
      before { stub_catalog({}, source: "unavailable") }

      it "still returns curated models rather than failing" do
        result = described_class.call

        expect(result.models).not_to be_empty
        expect(result.models.map { |m| m[:id] }).to include("ibm/granite-3-8b-instruct")
      end

      it "returns no models for a provider that only has a live source" do
        models = described_class.call(provider: "Anthropic").models

        expect(models).to be_empty
      end
    end

    context "provider source and defaults" do
      it "loads providers through FilterConnectorDefinitions without a workspace" do
        stub_catalog({})
        expect(HostedDataStores::HostedDataStoreTemplateList).not_to receive(:call)
        expect(ConnectorDefinitions::FilterConnectorDefinitions).to receive(:call)
          .with(hash_including(type: "source", category: "ai_ml"))
          .and_call_original

        expect { described_class.call }.not_to raise_error
      end

      it "omits catalog freshness fields the client no longer reads" do
        stub_catalog({})
        meta = described_class.call.meta

        expect(meta.keys).to contain_exactly(
          :total_count, :page, :per_page, :available_tasks, :available_provider_types
        )
      end

      it "keeps filter options from the unfiltered catalog" do
        stub_catalog({ "anthropic" => [live_model] })
        result = described_class.call(task: "Reasoning")

        expect(result.models.map { |m| m[:id] }).to include("claude-opus-5")
        expect(result.meta[:available_tasks]).to include("Text Embeddings")
      end

      it "treats a blank search as no search" do
        stub_catalog({})

        expect(described_class.call(q: "   ").models.size).to eq(described_class.call.models.size)
      end

      it "uses the default page size when per_page is not provided" do
        stub_catalog({})

        expect(described_class.call(page: 1).meta[:per_page]).to eq(20)
      end

      it "defaults missing provider fields" do
        allow(ConnectorDefinitions::FilterConnectorDefinitions).to receive(:call).and_return(
          double(connectors: [
                   {
                     name: "Custom",
                     title: "Custom",
                     icon: "icon.svg",
                     connector_spec: {
                       model_catalog: [{ id: "m1", name: "M", model_type: "llm", tasks: [] }]
                     }
                   }.with_indifferent_access
                 ])
        )

        model = described_class.call.models.first

        expect(model[:provider_type]).to eq("third_party")
        expect(model[:availability]).to eq("available")
        expect(model[:managed_by_ais]).to be(false)
        expect(model[:display_order]).to eq(described_class::DEFAULT_DISPLAY_ORDER)
      end

      it "skips providers that have no model catalog" do
        allow(ConnectorDefinitions::FilterConnectorDefinitions).to receive(:call).and_return(
          double(connectors: [
                   { name: "Empty", connector_spec: {} }.with_indifferent_access,
                   { name: "Missing" }.with_indifferent_access
                 ])
        )

        expect(described_class.call.models).to eq([])
      end
    end
  end
end
