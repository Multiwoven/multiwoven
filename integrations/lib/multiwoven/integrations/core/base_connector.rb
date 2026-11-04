# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class BaseConnector
      include Integrations::Protocol
      include Utils
      include Constants

      MAX_ERROR_MESSAGE_LENGTH = 500

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
        message = case error
                  when Exception then error.message
                  when String then error.presence
                  else error&.to_s
                  end
        message = "failed" if message.blank?

        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: message).to_multiwoven_message
      end

      def failure_status_from_response(response)
        failure_status(http_error_message(response))
      end

      def http_error_message(response)
        return "failed" if response.nil?

        body = response.body.to_s
        return readable_error_body(body, response) if body.blank?

        json_error_message(JSON.parse(body)).presence || readable_error_body(body, response)
      rescue StandardError
        readable_error_body(body.to_s, response)
      end

      def json_error_message(payload)
        return nil unless payload.is_a?(Hash)

        error = payload["error"] || payload["errors"]
        error = error.first if error.is_a?(Array)
        description = payload["error_description"].presence

        detailed_error_message(error, description) || payload["message"].presence || description
      end

      def detailed_error_message(error, description)
        case error
        when Hash then error["message"].presence || error["detail"].presence
        when String then description || error.presence
        end
      end

      def readable_error_body(body, response)
        text = body.to_s.scrub.strip
        return text.truncate(MAX_ERROR_MESSAGE_LENGTH) if text.present? && !text.start_with?("<")

        code = response.respond_to?(:code) ? response.code.to_s : nil
        code.present? ? "HTTP #{code}" : "failed"
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
