# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class BaseConnector
      include Integrations::Protocol
      include Utils
      include Constants

<<<<<<< HEAD
=======
      MAX_ERROR_MESSAGE_LENGTH = 500
      ANTHROPIC_DATE_SUFFIX = /-\d{8}\z/.freeze
      ANTHROPIC_VERSION_PATTERN = /
        \A(?:
          claude-(?:opus|sonnet|haiku)-(\d+)(?:[.-](\d+))?
          |
          claude-(\d+)(?:[.-](\d+))?-(?:opus|sonnet|haiku)
        )\z
      /x.freeze

>>>>>>> 74088209e (chore(CE): Add model exclusion for deprecated/unsupported models (#2219))
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
        model_id = (model&.dig(:id) || model&.dig("id")).to_s
        return false if openrouter_id.empty?

        return excluded_openai_model?(model_id) if openrouter_id.start_with?("openai/")
        return excluded_anthropic_model?(model_id) if openrouter_id.start_with?("anthropic/")

        false
      end

      def excluded_openai_model?(model_id)
        @open_ai_exclude_models ||= OPEN_AI_EXCLUDE_MODELS.split(",").map(&:strip).reject(&:empty?)
        @open_ai_exclude_models.include?(model_id)
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

>>>>>>> 74088209e (chore(CE): Add model exclusion for deprecated/unsupported models (#2219))
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
