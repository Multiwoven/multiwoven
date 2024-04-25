# frozen_string_literal: true

module Multiwoven
  module Integrations
    class Config
      attr_accessor :logger

      def initialize(params = {})
        @logger = params[:logger]
      end
    end
  end
end