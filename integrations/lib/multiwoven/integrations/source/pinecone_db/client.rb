# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module PineconeDB
    include Multiwoven::Integrations::Core
    class Client < VectorSourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        pinecone = create_connection(connection_config)
        result = pinecone.describe_index(@index_name)
        if success?(result)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, { context: "PINECONE:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "PINECONE:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def search(vector_search_config)
        connection_config = vector_search_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        connection = create_connection(connection_config)
        pinecone_index = connection.index(@index_name)
        response = pinecone_index.query(vector: vector_search_config[:vector],
                                        namespace: @namespace,
                                        top_k: vector_search_config[:limit],
                                        include_values: true,
                                        include_metadata: true)
        result = JSON.parse(response.body).with_indifferent_access
        records = result["matches"]
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "PINECONE:SEARCH:EXCEPTION",
                           type: "error"
                         })
      end

      private

      def create_connection(connection_config)
        initialize_client(connection_config)
        Pinecone.configure do |config|
          config.api_key = @api_key
          config.environment = @region
        end
        Pinecone::Client.new
      end

      def initialize_client(connection_config)
        @api_key = connection_config["api_key"]
        @region = connection_config["region"]
        @index_name = connection_config["index_name"]
        @namespace = connection_config["namespace"]
      end
    end
  end
end
