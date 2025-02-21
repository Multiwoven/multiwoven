# frozen_string_literal: true

module ReverseEtl
  module Transformers
    module Embeddings
      class Base
        def initialize(embedding_config)
          @embedding_config = embedding_config
        end

        def generate_embedding(text)
          raise NotImplementedError, "This method must be implemented in a subclass"
        end
      end
    end
  end
end
