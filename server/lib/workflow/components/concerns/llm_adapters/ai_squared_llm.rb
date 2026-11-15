# frozen_string_literal: true

module Workflow
  module Components
    module Concerns
      module LlmAdapters
        # Langchain LLM for AI Squared chat via `chat/completions` API.
        # Subclasses OpenAI so Langchain::Assistant picks the OpenAI adapter.
        class AiSquaredLlm < Langchain::LLM::OpenAI
          DEFAULTS = {
            temperature: 0.7,
            max_tokens: 4096
          }.freeze

          class Error < StandardError; end

          # rubocop:disable Lint/MissingSuper
          def initialize(default_options: {}, base_url: nil, http_client: nil)
            @base_url = base_url
            @http_client = http_client || Multiwoven::Integrations::Core::HttpClient
            @defaults = DEFAULTS.merge(default_options)
          end
          # rubocop:enable Lint/MissingSuper

          def chat(messages:, tools: [], temperature: nil, max_tokens: nil, **_opts)
            payload = build_payload(
              messages:,
              tools:,
              temperature: temperature.nil? ? @defaults[:temperature] : temperature,
              max_tokens: max_tokens.nil? ? @defaults[:max_tokens] : max_tokens
            )
            Langchain::LLM::OpenAIResponse.new(post_chat(payload))
          end

          private

          def build_payload(messages:, tools:, temperature:, max_tokens:)
            payload = { "messages" => messages }
            payload["temperature"] = temperature unless temperature.nil?
            payload["max_tokens"] = max_tokens unless max_tokens.nil?
            payload["tools"] = tools if tools.present?
            payload
          end

          def post_chat(payload)
            Rails.logger.info(
              "AI_SQUARED_CHAT_URL: #{chat_url}," \
              "HTTP_METHOD: POST, " \
              "PAYLOAD: #{payload.to_json}"
            )
            response = @http_client.request(
              chat_url,
              "POST",
              payload:,
              headers: {
                "Content-Type" => "application/json",
                "Authorization" => "Bearer #{api_key}"
              }
            )
            unless success?(response)
              Rails.logger.error("AI Squared LLM request failed with status #{response.code}: #{response.body}")
              raise Error, "AI Squared chat request failed with status #{response.code}: #{response.body}"
            end

            JSON.parse(response.body)
          rescue JSON::ParserError => e
            Rails.logger.error("AI Squared LLM failed to parse response: #{e.message}")
            raise Error, "Failed to parse AI Squared chat response: #{e.message}"
          end

          def chat_url
            host = (@base_url.presence || ENV.fetch("AISQUARED_CHAT_ENDPOINT_URL", nil)).to_s.strip
            raise Error, "AISQUARED_CHAT_ENDPOINT_URL is not configured" if host.empty?

            host
          end

          def api_key
            key = ENV.fetch("AISQUARED_BOLT_API_KEY", nil).to_s.strip
            raise Error, "AISQUARED_BOLT_API_KEY is not configured" if key.empty?

            key
          end

          def success?(response)
            response && %w[200 201].include?(response.code.to_s)
          end
        end
      end
    end
  end
end
