# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module GoogleGemini
    include Multiwoven::Integrations::Core
    # Gemini exposes an OpenAI-compatible chat completions API, so the request,
    # streaming and response handling is identical to GenericOpenAI. Only the
    # config/ directory differs, and BaseConnector#read_json resolves that from
    # this class's own source location.
    class Client < GenericOpenAI::Client
      private

      def log_context
        "GOOGLE GEMINI"
      end
    end
  end
end
