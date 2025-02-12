# frozen_string_literal: true

module ReverseEtl
  module Transformers
    module Embeddings
      class EmbeddingService
        def initialize(embedding_config:)
          @embedding_config = embedding_config
        end

        def generate_embedding(text)
          class_name = "ReverseEtl::Transformers::Embeddings::#{@embedding_config[:mode].camelize}"

          unless Object.const_defined?(class_name)
            raise StandardError,
                  "Embedding mode '#{@embedding_config[:mode]}' is not supported. Class '#{class_name}' not found."
          end

          service_class = class_name.constantize
          service = service_class.new(@embedding_config)
          service.generate_embedding(text)
        end
      end
    end
  end
end
