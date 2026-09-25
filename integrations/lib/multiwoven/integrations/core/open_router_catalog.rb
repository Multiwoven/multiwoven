# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    # Live model metadata from OpenRouter's public /models endpoint, so a connector
    # need not ship prices that go stale. Providers opt in with an openrouter_slug;
    # embeddings and partner-hosted models stay curated in models.json.
    class OpenRouterCatalog
      MODELS_URL = "https://openrouter.ai/api/v1/models"
      CACHE_KEY = "multiwoven_open_router_catalog_v1"
      CACHE_TTL = 86_400
      REQUEST_CONFIG = { timeout: 10, open_timeout: 5 }.freeze
      PER_MILLION = 1_000_000

      Result = Struct.new(:models_by_slug, :fetched_at, :source, keyword_init: true) do
        def models_for(slug)
          return [] if slug.blank?

          models_by_slug.fetch(slug.to_s.downcase, [])
        end
      end

      class << self
        # Two layers: a host cache may be absent or a null store, so the memo is
        # what prevents a re-fetch of half a megabyte per request.
        def fetch
          return @memo if live_memo?

          result = to_result(cached_payload)
          @memo = result if result.source == "live"
          result
        end

        def reset!
          @memo = nil
          cache&.delete(CACHE_KEY)
        rescue StandardError => e
          log_cache_failure("delete", e)
        end

        private

        def cache
          Integrations::Service.config.cache
        end

        def live_memo?
          @memo&.source == "live" && @memo.fetched_at && @memo.fetched_at > Time.now - CACHE_TTL
        end

        def cached_payload
          store = cache
          return build_payload if store.nil?

          cached = read_cache(store)
          return cached if live_payload?(cached)

          payload = build_payload
          write_cache(store, payload) if live_payload?(payload)
          payload
        end

        # A failing host cache degrades to a direct fetch rather than taking the
        # whole catalog down with it.
        def read_cache(store)
          store.read(CACHE_KEY)
        rescue StandardError => e
          log_cache_failure("read", e)
          nil
        end

        def write_cache(store, payload)
          store.write(CACHE_KEY, payload, expires_in: CACHE_TTL)
        rescue StandardError => e
          log_cache_failure("write", e)
        end

        def log_cache_failure(operation, error)
          Integrations::Service.logger.error(
            "OpenRouterCatalog: cache #{operation} failed: #{error.class}: #{error.message}"
          )
        end

        def live_payload?(payload)
          payload.present? && payload.with_indifferent_access[:source] == "live"
        end

        # Slugs stay strings because models_for looks them up that way; the model
        # hashes are symbolized because every reader indexes them with symbols.
        def symbolize_models(by_slug)
          (by_slug || {}).each_with_object({}) do |(slug, models), acc|
            acc[slug.to_s.downcase] = Array(models).map(&:deep_symbolize_keys)
          end
        end

        def to_result(payload)
          payload = payload.transform_keys(&:to_sym)
          Result.new(
            models_by_slug: symbolize_models(payload[:models_by_slug]),
            fetched_at: payload[:fetched_at],
            source: payload[:source]
          )
        end

        def build_payload
          response = Integrations::Core::HttpClient.request(
            MODELS_URL, "GET", options: { config: REQUEST_CONFIG }
          )
          body = JSON.parse(response.body)
          raise "OpenRouter returned no data" unless body["data"].is_a?(Array)

          { models_by_slug: group_by_slug(body["data"]), fetched_at: Time.now, source: "live" }
        rescue StandardError => e
          # Fail soft: callers still see curated models rather than an exception.
          Integrations::Service.logger.error("OpenRouterCatalog: #{e.class}: #{e.message}")
          { models_by_slug: {}, fetched_at: Time.now, source: "unavailable" }
        end

        def group_by_slug(raw_models)
          grouped = raw_models.each_with_object({}) do |raw, acc|
            slug, = raw["id"].to_s.split("/", 2)
            next if slug.blank?

            (acc[slug.downcase] ||= []) << normalize(raw, slug.downcase)
          end
          grouped.transform_values { |models| sort_models(models) }
        end

        # Newest first: a live list has no curation.
        def sort_models(models)
          models.sort_by { |model| [-model[:released_at].to_i, model[:name].to_s.downcase] }
                .each { |model| model.delete(:released_at) }
        end

        def normalize(raw, slug)
          architecture = raw["architecture"] || {}
          inputs = Array(architecture["input_modalities"])
          outputs = Array(architecture["output_modalities"])
          pricing = raw["pricing"] || {}

          {
            id: strip_slug(raw["id"]),
            openrouter_id: raw["id"],
            name: display_name(raw, slug),
            model_type: outputs.include?("image") ? "vision" : "llm",
            type: outputs.include?("image") ? "image" : "completion",
            tasks: derive_tasks(raw, outputs),
            capabilities: derive_capabilities(raw, inputs, pricing),
            context_window: raw["context_length"]&.to_i,
            max_output: raw.dig("top_provider", "max_completion_tokens")&.to_i,
            pricing: {
              input: per_million(pricing["prompt"]),
              output: per_million(pricing["completion"]),
              cached_read: per_million(pricing["input_cache_read"]),
              cached_write: per_million(pricing["input_cache_write"]),
              unit: "per_1m_tokens"
            },
            availability: "available",
            unavailable_reason: nil,
            released_at: raw["created"]
          }
        end

        # Ids are "<provider-slug>/<model-slug>", and the slug is OpenRouter's own
        # normalization — a provider may pin the real one.
        def strip_slug(id)
          id.to_s.split("/", 2).last.to_s
        end

        # Names are prefixed with the vendor ("OpenAI: GPT-4o") and the UI already
        # shows it. Drop it only when the prefix really is the provider.
        def display_name(raw, slug)
          name = raw["name"].presence || strip_slug(raw["id"])
          prefix, remainder = name.split(":", 2)
          return name if remainder.blank?
          return name unless prefix.to_s.downcase.gsub(/[^a-z0-9]/, "") == slug.gsub(/[^a-z0-9]/, "")

          remainder.strip
        end

        def derive_tasks(raw, outputs)
          tasks = []
          tasks << "Text Generation" if outputs.include?("text")
          tasks << "Text-to-Image" if outputs.include?("image")
          params = Array(raw["supported_parameters"])
          tasks << "Reasoning" if params.include?("reasoning") || params.include?("include_reasoning")
          tasks.uniq
        end

        def derive_capabilities(raw, inputs, pricing)
          params = Array(raw["supported_parameters"])
          capabilities = []
          capabilities << "Image analysis" if inputs.include?("image")
          capabilities << "Documents" if inputs.include?("file")
          capabilities << "Audio" if inputs.include?("audio")
          capabilities << "Web search" if pricing["web_search"].present?
          capabilities << "Tool use" if params.include?("tools")
          capabilities << "Structured output" if params.include?("structured_outputs")
          capabilities
        end

        # Quoted per token as strings; the contract is per million. A genuine zero
        # stays 0.0, a missing field stays nil so the UI renders "—" not "$0".
        def per_million(value)
          return nil if value.nil? || value.to_s.strip.empty?

          (value.to_f * PER_MILLION).round(4)
        end
      end
    end
  end
end
