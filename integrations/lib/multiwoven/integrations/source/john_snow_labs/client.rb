# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module JohnSnowLabs
    include Multiwoven::Integrations::Core
    # John Snow Labs exposes an OpenAI-compatible chat completions API, so the request,
    # streaming and response handling is identical to GenericOpenAI. Only the
    # config/ directory differs, and BaseConnector#read_json resolves that from
    # this class's own source location.
    class Client < GenericOpenAI::Client
      private

      def log_context
        "JOHN SNOW LABS"
      end
    end
  end
end
