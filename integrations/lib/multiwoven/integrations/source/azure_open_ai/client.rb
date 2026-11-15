# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module AzureOpenAI
    include Multiwoven::Integrations::Core
    # Azure OpenAI exposes an OpenAI-compatible chat completions API, so request,
    # streaming and response handling reuse GenericOpenAI. Auth uses Azure's
    # api-key header rather than Bearer.
    class Client < GenericOpenAI::Client
      private

      def log_context
        "AZURE OPEN AI"
      end

      def auth_headers(access_token)
        {
          "Accept" => "application/json",
          "api-key" => access_token.to_s,
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
