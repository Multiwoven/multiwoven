# frozen_string_literal: true

module ReverseEtl
  module Transformers
    class Base
      def transform(_sync_config, _sync_records)
        raise "Not implemented"
      end
    end
  end
end
