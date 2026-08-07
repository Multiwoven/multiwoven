# frozen_string_literal: true

module ReverseEtl
  module Transformers
    module Embeddings
      class HuggingFace < Base
        class HuggingFaceError < StandardError; end

        HUGGING_FACE_EMBEDDING_URL = "https://router.huggingface.co/hf-inference/models/sentence-transformers"

        def initialize(embedding_config)
          super(embedding_config)
          @api_key = embedding_config[:api_key]
          @model = embedding_config[:model]
        end

        def generate_embedding(text)
          hugging_face_embedding_request(text)
        end

        private

        def hugging_face_embedding_request(text)
          http_method = "POST"
          payload = {
            inputs: text,
            normalize: true
          }
          headers = {
            "Authorization" => "Bearer #{@api_key}",
            "Content-Type" => "application/json"
          }

          begin
            response = Multiwoven::Integrations::Core::HttpClient.request(
              "#{HUGGING_FACE_EMBEDDING_URL}/#{@model}/pipeline/feature-extraction",
              http_method,
              payload:,
              headers:
            )
            unless success?(response)
              raise HuggingFaceError, "Hugging Face request failed with status #{response.code}: #{response.body}"
            end

            JSON.parse(response.body)
          rescue JSON::ParserError => e
            raise HuggingFaceError, "Failed to parse response from Hugging Face: #{e.message}"
          rescue StandardError => e
            raise HuggingFaceError, "An error occurred while making the Hugging Face request: #{e.message}"
          end
        end

        def success?(response)
          response && %w[200 201].include?(response.code.to_s)
        end
      end
    end
  end
end
