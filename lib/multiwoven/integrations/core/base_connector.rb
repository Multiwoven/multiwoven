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
        icon_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven-integrations/#{MAIN_BRANCH_SHA}#{relative_path}/#{icon_name}"
        client_meta_data[:data][:icon] = icon_url
        # returns hash
        @meta_data ||= client_meta_data
      end

      def relative_path
        path = Object.const_source_location(self.class.to_s)[0]
        connector_folder = File.dirname(path)
        marker = "multiwoven-integrations"
        parts = connector_folder.split(marker)

        parts.last if parts.length > 1
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
    end
  end
end
