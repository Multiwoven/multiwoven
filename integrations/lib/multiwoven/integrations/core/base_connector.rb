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
<<<<<<< HEAD
        client_meta_data = read_json(META_DATA_PATH).deep_symbolize_keys
        icon_name = client_meta_data[:data][:icon]
        icon_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations#{relative_path}/#{icon_name}"
        client_meta_data[:data][:icon] = icon_url
        # returns hash
        @meta_data ||= client_meta_data
=======
        return @meta_data if @meta_data

        # returns hash
        @meta_data = read_json(META_DATA_PATH).deep_symbolize_keys
      end

      def model_catalog
        @model_catalog ||= ModelCatalog.new(models: (live_models + curated_models).uniq { |model| model[:id] })
      rescue Dry::Struct::Error => e
        Integrations::Service.logger.error("#{self.class}: unusable model catalog: #{e.message}")
        @model_catalog = ModelCatalog.new(models: [])
      end

      # Symbolized to match models from upstream; read_json hands back string keys,
      # which leaves callers reading nil.
      def curated_models
        @curated_models ||= Array(read_json(MODELS_SPEC_PATH)["models"]).map(&:deep_symbolize_keys)
      rescue Errno::ENOENT
        @curated_models = []
      rescue StandardError => e
        Integrations::Service.logger.error("#{self.class}: unusable models.json: #{e.message}")
        @curated_models = []
      end

      def live_models
        slug = meta_data[:data][:openrouter_slug]
        return [] if slug.blank?

        overrides = meta_data[:data][:model_id_overrides] || {}
        Integrations::Core::OpenRouterCatalog.fetch.models_for(slug).map do |model|
          pinned = overrides[model[:id].to_sym] || overrides[model[:id].to_s]
          pinned.present? ? model.merge(id: pinned) : model
        end
>>>>>>> 27ec87468 (chore(CE): update icon URL path (#2178))
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
