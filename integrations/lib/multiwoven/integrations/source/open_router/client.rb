# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module OpenRouter
    include Multiwoven::Integrations::Core
    # OpenAI-compatible gateway. Model Hub loads the full OpenRouter catalog via
    # openrouter_slug: "*" in meta.json (provider/model ids).
    class Client < GenericOpenAI::Client
      private

      def log_context
        "OPEN ROUTER"
      end
    end
  end
end
