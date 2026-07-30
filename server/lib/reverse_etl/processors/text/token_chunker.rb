# frozen_string_literal: true

module ReverseEtl
  module Processors
    module Text
      class TokenChunker < BaseDocProcessor
        include ::Utils::Constants
        def process(chunk_config, content)
          @model = chunk_config[:model]
          @provider = chunk_config[:provider]
          @chunk_size = chunk_config[:chunk_size]
          validate_model
          initialize_tokeniser
          tokens = get_tokens(content)
          tokens_to_text_chunks(tokens, @chunk_size)
        end

        private

        def open_ai?
          @provider == "open_ai"
        end

        def tokens_to_text_chunks(arr, chunk_size)
          arr.each_slice(chunk_size).map do |chunk|
            if open_ai?
              @tokeniser.decode(chunk)
            else
              @tokeniser.decode(chunk).join(" ")
            end
          end
        end

        def validate_model
          raise TypeError, "Model is required" if @model.blank?
          raise TypeError, "Embedding model #{@model} not supported" unless EMBEDDING_MODEL_TOKEN_LIMITS.key?(@model)
        end

        def initialize_tokeniser
          raise TypeError, "Provider is required" if @provider.blank?
          raise TypeError, "Provider #{@provider} not supported" unless SUPPORTED_PROVIDERS.include?(@provider)

          @tokeniser = if open_ai?
                         Tiktoken.encoding_for_model(@model)
                       else
                         Tokenizers::Tokenizer.from_pretrained("sentence-transformers/#{@model}")
                       end
        end

        def get_tokens(text)
          if open_ai?
            @tokeniser.encode(text)
          else
            @tokeniser.encode(text).tokens
          end
        end
      end
    end
  end
end
