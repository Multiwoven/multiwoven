# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Groq
    include Multiwoven::Integrations::Core
    # Groq exposes an OpenAI-compatible chat completions API, so the request,
    # streaming and response handling is identical to GenericOpenAI. Only the
    # config/ directory differs, and BaseConnector#read_json resolves that from
    # this class's own source location.
    #
    # Model Hub stays curated in config/models.json: OpenRouter has no groq/*
    # author, and its meta-llama/* ids are not GroqCloud API ids.
    class Client < GenericOpenAI::Client
      private

      def log_context
        "GROQ"
      end
    end
  end
end
