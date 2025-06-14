# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Qdrant
    include Multiwoven::Integrations::Core
    class Client < VectorSourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        response = Multiwoven::Integrations::Core::HttpClient.request(
          @host,
          HTTP_GET,
          headers: auth_headers(@api_key)
        )
        if success?(response)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "QDRANT:CHECK_CONNECTION:EXCEPTION",
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
                           context: "QDRANT:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def search(vector_search_config)
        connection_config = vector_search_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        url = build_url(QDRANT_SEARCH_URL)

        body = {
          vector: vector_search_config[:vector],
          top: vector_search_config[:limit]
        }

        response = Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_POST,
          headers: {
            "Content-Type" => "application/json",
            "api-key" => @api_key
          },
          payload: body
        )

        response = JSON.parse(response.body).with_indifferent_access
        records = response[:result] || []

        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "QDRANT:SEARCH:EXCEPTION",
                           type: "error"
                         })
      end

      private

      def create_connection(connection_config)
        @api_key = connection_config[:api_key]
        @host = connection_config[:host]
        @collection_name = connection_config[:collection_name]
      end

      def build_url(url)
        format(url, host: @host, collection_name: @collection_name)
      end
    end
  end
end
