# frozen_string_literal: true

module Multiwoven
  module Integrations
    class Config
      # cache: optional host store responding to read(key), write(key, value,
      # expires_in:) and delete(key). Without one, caching is a per-process memo.
      attr_accessor :logger, :exception_reporter, :cache

      def initialize(params = {})
        @logger = params[:logger]
        @exception_reporter = params[:exception_reporter]
        @cache = params[:cache]
      end
    end
  end
end
