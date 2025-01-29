# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module MicrosoftDynamics
    include Multiwoven::Integrations::Core
    API_VERSION = "9.2"
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        initialize_client(connection_config)
        token_response = create_access_token
        uri = URI.parse(format(MS_DYNAMICS_WHOAMI_API, instance_url: @instance_url, api_version: API_VERSION))
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        request = Net::HTTP::Get.new(uri)
        auth_headers(token_response["access_token"]).each { |key, value| request[key] = value }
        response = http.request(request)
        response_body = JSON.parse(response.body)

        if success?(response) && response_body.key?("UserId")
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "MICROSOFT:DYNAMICS:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "MICROSOFT:DYNAMICS:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "upsert")
        @sync_config = sync_config
        stream = @sync_config.stream
        connection_config = @sync_config.destination.connection_specification.with_indifferent_access
        create_connection(connection_config)
        build_url(stream)
        process_records(records, stream)
      rescue StandardError => e
        handle_exception(e, {
                           context: "MICROSOFT:DYNAMICS:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: @sync_config.sync_id,
                           sync_run_id: @sync_config.sync_run_id
                         })
      end

      private

      def create_access_token
        uri = URI.parse("https://login.microsoftonline.com/#{@tenant_id}/oauth2/v2.0/token")

        payload = {
          client_id: @client_id,
          client_secret: @client_secret,
          scope: "https://#{@instance_url}.crm.dynamics.com/.default",
          grant_type: "client_credentials"
        }

        response = Net::HTTP.post_form(uri, payload)
        JSON.parse(response.body)
      end

      def get_access_token(cache)
        cache_key = "dynamics_#{@instance_url}_#{@tenant_id}_#{@client_id}"
        cached_token = cache.read(cache_key)
        if cached_token
          @access_token = cached_token
        else
          new_token = create_access_token
          # max expiration is 3 minutes. No way to make it higher
          cache.write(cache_key, new_token["access_token"], expires_in: 180)
          @access_token = new_token["access_token"]
        end
      end

      def create_connection(connection_config)
        cache = defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
        initialize_client(connection_config)
        get_access_token(cache)
      end

      def initialize_client(connection_config)
        @tenant_id = connection_config[:tenant_id]
        @client_id = connection_config[:application_id]
        @instance_url = connection_config[:instance_url]
        @client_secret = connection_config[:client_secret]
      end

      def process_records(records, stream)
        write_success = 0
        write_failure = 0
        properties = stream.json_schema[:properties]
        log_message_array = []

        records.each do |record_object|
          record = extract_data(record_object, properties)
          response = send_data_to_dynamics(record)
          response_code = response.code.to_i
          if response_code >= 200 && response_code < 300
            write_success += 1
            log_message_array << log_request_response("info", record, response["location"])
          else
            write_failure += 1
            log_message_array << log_request_response("error", record, response.body)
          end
        rescue StandardError => e
          # TODO: add sync_id and sync run id to the logs
          handle_exception(e, {
                             context: "MICROSOFT:DYNAMICS:WRITE:EXCEPTION",
                             type: "error",
                             sync_id: @sync_config.sync_id,
                             sync_run_id: @sync_config.sync_run_id
                           })
          write_failure += 1
          log_message_array << log_request_response("error", record, e.message)
        end
        tracking_message(write_success, write_failure, log_message_array)
      end

      def build_url(stream)
        @destination_url = format(MS_DYNAMICS_REST_API, instance_url: @instance_url, api_version: API_VERSION, entity: stream.name)
      end

      def send_data_to_dynamics(payload)
        uri = URI.parse(@destination_url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")

        request = Net::HTTP::Post.new(uri)
        auth_headers(@access_token).each { |key, value| request[key] = value }
        request.body = payload.to_json
        http.request(request)
      end
    end
  end
end
