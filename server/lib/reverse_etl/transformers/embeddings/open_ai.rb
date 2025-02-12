# frozen_string_literal: true

module ReverseEtl
  module Transformers
    module Embeddings
      class OpenAi < Base
        class OpenAIError < StandardError; end

        OPENAI_EMBEDDING_URL = "https://api.openai.com/v1/embeddings"

        def initialize(embedding_config)
          super(embedding_config)
          @api_key = embedding_config[:api_key]
          @model = embedding_config[:model]
        end

        def generate_embedding(text)
          response = openai_embedding_request(text)
          response["data"]&.first&.fetch("embedding", nil)
        end

        private

        def openai_embedding_request(text)
          http_method = "POST"
          payload = {
            model: @model,
            input: text
          }
          headers = {
            "Authorization" => "Bearer #{@api_key}",
            "Content-Type" => "application/json"
          }

          begin
            response = Multiwoven::Integrations::Core::HttpClient.request(
              OPENAI_EMBEDDING_URL,
              http_method,
              payload:,
              headers:
            )

            unless success?(response)
              raise OpenAIError, "OpenAI request failed with status #{response.code}: #{response.body}"
            end

            JSON.parse(response.body)
          rescue JSON::ParserError => e
            raise OpenAIError, "Failed to parse response from OpenAI: #{e.message}"
          rescue StandardError => e
            raise OpenAIError, "An error occurred while making the OpenAI request: #{e.message}"
          end
        end

        def success?(response)
          response && %w[200 201].include?(response.code.to_s)
        end
      end
    end
  end
end
