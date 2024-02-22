# frozen_string_literal: true

module ReverseEtl
  module Loaders
    class Base
      def write(_sync_run_id)
        raise "Not implemented"
      end
    end
  end
end
