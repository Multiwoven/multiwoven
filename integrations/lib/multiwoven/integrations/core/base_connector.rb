# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class BaseConnector
      include Integrations::Protocol
      include Utils
      include Constants

      def connector_spec
        @connector_spec ||= begin
          spec_json = keys_to_symbols(read_json(CONNECTOR_SPEC_PATH)).to_json
          # returns Protocol::ConnectorSpecification
          ConnectorSpecification.from_json(spec_json)
        end
      end

      def meta_data
        client_meta_data = read_json(META_DATA_PATH).deep_symbolize_keys
        icon_name = client_meta_data[:data][:icon]
        icon_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations#{relative_path}/#{icon_name}"
        client_meta_data[:data][:icon] = icon_url
        # returns hash
        @meta_data ||= client_meta_data
      end

      def relative_path
        path = Object.const_source_location(self.class.to_s)[0]
        connector_folder = File.dirname(path)
        marker = "/lib/multiwoven/integrations/"
        parts = connector_folder.split(marker)

        marker + parts.last if parts.length > 1
      end

      # Connection config is a hash
      def check_connection(_connection_config)
        raise "Not implemented"
        # returns Protocol.ConnectionStatus
      end

      # Connection config is a hash
      def discover(_connection_config)
        raise "Not implemented"
        # returns Protocol::Catalog
      end

      private

<<<<<<< HEAD
=======
      # Only list what the connector can actually serve. No connector has an
      # image-generation payload path and deprecated models are dropped everywhere.
      def include_model?(model)
        !image_output_model?(model) && !excluded_model?(model)
      end

      def image_output_model?(model)
        (model[:type] || model["type"]).to_s == "image"
      end

      def embedding_model?(model)
        [model[:type] || model["type"], model[:model_type] || model["model_type"]]
          .any? { |value| value.to_s == "embedding" }
      end

      def excluded_model?(model)
        openrouter_id = (model&.dig(:openrouter_id) || model&.dig("openrouter_id")).to_s
        return false if openrouter_id.empty?

        # Provider routing uses openrouter_id; list/version checks use the catalog
        # id we show/send (after model_id_overrides), not the openrouter_id segment.
        normalized_id = openrouter_id.delete_prefix("~")
        model_id = (model&.dig(:id) || model&.dig("id")).to_s

        # Gateway catalogs only honor OPEN_ROUTER_EXCLUDE_PROVIDERS. First-party
        # lists (OPENAI_EXCLUDE_MODELS, etc.) mean "unsupported on that API", not
        # "hide from OpenRouter which can still serve it".
        if open_router_gateway?
          excluded_openrouter_provider?(normalized_id)
        else
          excluded_model_for_provider?(normalized_id, model_id)
        end
      end

      # OPEN_ROUTER_EXCLUDE_PROVIDERS only applies to the OpenRouter gateway catalog
      # (openrouter_slug: "*"). First-party connectors reuse openrouter_id prefixes
      # like "openai/..." and must not be emptied by that env var.
      def open_router_gateway?
        meta_data.dig(:data, :openrouter_slug).to_s == "*"
      end

      def excluded_model_for_provider?(openrouter_id, model_id)
        case openrouter_id
        when %r{\Aopenai/} then excluded_openai_model?(model_id)
        when %r{\Aanthropic/} then excluded_anthropic_model?(model_id)
        when %r{\Agoogle/} then excluded_google_gemini_model?(model_id)
        else false
        end
      end

      def excluded_openrouter_provider?(openrouter_id)
        provider = openrouter_id.to_s.split("/", 2).first
        @open_router_exclude_providers ||= OPEN_ROUTER_EXCLUDE_PROVIDERS.split(",").map do |entry|
          entry.strip.downcase
        end.reject(&:empty?)
        @open_router_exclude_providers.include?(provider.downcase)
      end

      def excluded_openai_model?(model_id)
        @openai_exclude_models ||= OPENAI_EXCLUDE_MODELS.split(",").map(&:strip).reject(&:empty?)
        @openai_exclude_models.include?(model_id)
      end

      def excluded_anthropic_model?(model_id)
        threshold = ANTHROPIC_EXCLUDE_MODELS.to_s.strip
        return false if threshold.empty? || !Gem::Version.correct?(threshold)

        version = anthropic_model_version(model_id)
        return false if version.nil? || !Gem::Version.correct?(version)

        Gem::Version.new(version) < Gem::Version.new(threshold)
      end

      def anthropic_model_version(model_id)
        base = model_id.to_s.sub(ANTHROPIC_DATE_SUFFIX, "")
        match = ANTHROPIC_VERSION_PATTERN.match(base)
        return unless match

        major = match[1] || match[3]
        minor = match[2] || match[4]
        minor ? "#{major}.#{minor}" : major
      end

      def excluded_google_gemini_model?(model_id)
        @google_gemini_exclude_models ||= GOOGLE_GEMINI_EXCLUDE_MODELS.split(",").map(&:strip).reject(&:empty?)
        @google_gemini_exclude_models.include?(model_id)
      end

>>>>>>> f2c498c05 (chore(CE): Add Azure OpenAI, Groq, Open Router, and xAI as AI/ML Connector (#2233))
      def read_json(file_path)
        path = Object.const_source_location(self.class.to_s)[0]
        connector_folder = File.dirname(path)
        file_path = File.join(
          "#{connector_folder}/",
          file_path
        )
        file_contents = File.read(file_path)
        JSON.parse(file_contents)
      end

      def success_status
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      end

      def failure_status(error)
        message = error&.message || "failed"
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: message).to_multiwoven_message
      end

      def auth_headers(access_token)
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
