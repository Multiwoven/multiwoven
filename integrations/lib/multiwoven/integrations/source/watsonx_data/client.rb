# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module WatsonxData
    include Multiwoven::Integrations::Core
    API_VERSION = "2021-05-01"
    class Client < SourceConnector
      def check_connection(connection_config)
        create_connection(connection_config)
        response = execute_query(connection_config, "show catalogs")
        success?(response) ? success_status : failure_status(nil)
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX DATA:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name,
                  data_type,
                  is_nullable
                  FROM information_schema.columns
                  WHERE table_schema = '#{connection_config[:schema]}' AND table_catalog = '#{connection_config[:database]}'
                  ORDER BY table_name, ordinal_position"
        response = execute_query(connection_config, query)
        records = JSON.parse(response.body)["response"]["result"]
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX DATA:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        query = sync_config.model.query
        if connection_config[:engine] == "presto"
          query = batched_query_for_presto(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        else
          query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        end
        query(connection_config, query)
      rescue StandardError => e
        handle_exception(e, { context: "WATSONX DATA:READ:EXCEPTION", type: "error" })
      end

      private

      def batched_query_for_presto(query, limit, offset)
        <<~SQL
          SELECT * FROM (
            SELECT *, ROW_NUMBER() OVER () as rownum FROM ( #{query} ) subquery
          ) t
          WHERE rownum > #{offset}
          LIMIT #{limit}
        SQL
      end

      def execute_query(connection_config, query)
        connection_config.with_indifferent_access
        get_access_token(connection_config[:api_key])
        url = format(
          WATSONX_DATA_QUERIES_URL,
          region: connection_config[:region],
          engine_id: connection_config[:engine_id]
        )
        headers = auth_headers(@access_token)
        headers["AuthInstanceId"] = connection_config[:auth_instance_id]
        send_request(
          url: url,
          http_method: HTTP_POST,
          payload: {
            sql_string: query,
            catalog_name: connection_config[:database],
            schema_name: connection_config[:schema]
          },
          headers: headers,
          config: connection_config[:config]
        )
      end

      def query(connection, query)
        response = execute_query(connection, query)
        response = JSON.parse(response.body).with_indifferent_access
        records = response[:response][:result]
        records.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def create_connection(connection_config)
        connection_config
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:tablename], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        records.group_by { |entry| entry["table_name"] }.map do |table_name, columns|
          {
            tablename: table_name,
            columns: columns.map do |column|
              {
                column_name: column["column_name"],
                type: column["data_type"],
                optional: column["is_nullable"] == "YES"
              }
            end
          }
        end
      end

      def get_access_token(api_key)
        cache = defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : ActiveSupport::Cache::MemoryStore.new
        cache_key = "watsonx_data_#{api_key}"
        cached_token = cache.read(cache_key)
        if cached_token
          @access_token = cached_token
        else
          new_token = get_iam_token(api_key)
          # puts new_token
          # max expiration is 3 minutes. No way to make it higher
          cache.write(cache_key, new_token, expires_in: 180)
          @access_token = new_token
        end
      end

      def get_iam_token(api_key)
        uri = URI("https://iam.cloud.ibm.com/identity/token")
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=#{api_key}"
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        raise "Failed to get IAM token: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)["access_token"]
      end
    end
  end
end
