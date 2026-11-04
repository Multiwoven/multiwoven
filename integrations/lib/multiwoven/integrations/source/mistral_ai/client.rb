# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module MistralAi
    include Multiwoven::Integrations::Core
    # Mistral exposes an OpenAI-compatible chat completions API, so read/stream
    # handling matches GenericOpenAI.
    #
    # Model Hub stays curated in config/models.json: OpenRouter's mistralai/* ids
    # (e.g. mistral-large) do not match Mistral API aliases (mistral-large-latest).
    class Client < GenericOpenAI::Client
      private

      def log_context
        "MISTRAL_AI"
      end
    end
  end
end
