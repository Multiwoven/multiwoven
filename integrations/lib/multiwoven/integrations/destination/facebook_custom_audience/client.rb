# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module FacebookCustomAudience
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      prepend Multiwoven::Integrations::Core::RateLimiter
      MAX_CHUNK_SIZE = 10_000
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        access_token = connection_config[:access_token]
        response = Multiwoven::Integrations::Core::HttpClient.request(
          FACEBOOK_AUDIENCE_GET_ALL_ACCOUNTS,
          HTTP_GET,
          headers: auth_headers(access_token)
        )
        if success?(response)
          ad_account_exists?(response, connection_config[:ad_account_id])
          ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
        else
          ConnectionStatus.new(status: ConnectionStatusType["failed"]).to_multiwoven_message
        end
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "FACEBOOK AUDIENCE:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        access_token = connection_config[:access_token]
        url = generate_url(sync_config, connection_config)
        write_success = 0
        write_failure = 0
        records.each_slice(MAX_CHUNK_SIZE) do |chunk|
          payload = create_payload(chunk, sync_config.stream.json_schema.with_indifferent_access)
          response = Multiwoven::Integrations::Core::HttpClient.request(
            url,
            sync_config.stream.request_method,
            payload: payload,
            headers: auth_headers(access_token)
          )
          if success?(response)
            write_success += chunk.size
          else
            write_failure += chunk.size
          end
        rescue StandardError => e
          handle_exception(e, {
                             context: "FACEBOOK:RECORD:WRITE:EXCEPTION",
                             type: "error",
                             sync_id: sync_config.sync_id,
                             sync_run_id: sync_config.sync_run_id
                           })
          write_failure += chunk.size
        end

        tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: write_success,
          failed: write_failure
        )
        tracker.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "FACEBOOK:RECORD:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def generate_url(sync_config, connection_config)
        sync_config.stream.url.gsub("{audience_id}", connection_config[:audience_id])
      end

      def create_payload(records, json_schema)
        schema, data = extract_schema_and_data(records, json_schema)
        {
          "payload" => {
            "schema" => schema,
            "data" => data
          }
        }
      end

      def extract_schema_and_data(records, json_schema)
        schema_properties = json_schema[:properties]
        schema = records.first.keys.map(&:to_s).map(&:upcase)
        data = []
        records.each do |record|
          encrypted_data_array = []
          record.with_indifferent_access.each do |key, value|
            schema_key = key.upcase
            encrypted_value = schema_properties[schema_key] && schema_properties[schema_key]["x-hashRequired"] ? Digest::SHA256.hexdigest(value.to_s) : value
            encrypted_data_array << encrypted_value
          end
          data << encrypted_data_array
        end
        [schema, data]
      end

      def auth_headers(access_token)
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      end

      def ad_account_exists?(response, ad_account_id)
        return if extract_data(response).any? { |ad_account| ad_account["id"] == "act_#{ad_account_id}" }

        raise ArgumentError, "Ad account not found in business account"
      end

      def extract_data(response)
        response_body = response.body
        JSON.parse(response_body)["data"] if response_body
      end
    end
  end
end
