# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class VectorSourceConnector < SourceConnector
      # This needs to be implemented
      # for all vector database sources
      # that will be used in RAG workflows
      def search(_vector_search_config)
        raise "Not implemented"
      end
    end
  end
end
