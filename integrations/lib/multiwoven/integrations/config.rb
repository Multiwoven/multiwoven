# frozen_string_literal: true

module Multiwoven
  module Integrations
    class Config
      attr_accessor :logger, :exception_reporter

      def initialize(params = {})
        @logger = params[:logger]
        @exception_reporter = params[:exception_reporter]
      end
    end
  end
end
