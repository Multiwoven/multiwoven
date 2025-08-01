# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module IntuitQuickBooks
    include Multiwoven::Integrations::Core

    QUICKBOOKS_OBJECTS = %w[Account Customer Employee Invoice TimeActivity].freeze
    MAX_PER_PAGE = 1000

    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        access_token = create_connection(connection_config)
        query = "SELECT * FROM Customer STARTPOSITION 1 MAXRESULTS 1"
        response = query_quickbooks(access_token, query)
        if success?(response)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, { context: "INTUIT_QUICKBOOKS:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        access_token = create_connection(connection_config)
        catalog = build_catalog(load_catalog.with_indifferent_access)
        streams = catalog[:streams]
        QUICKBOOKS_OBJECTS.each do |object|
          query = "SELECT * FROM #{object}"
          response = query_quickbooks(access_token, query)
          streams << create_streams(JSON.parse(response.body)["QueryResponse"])[0]
        rescue StandardError => e
          handle_exception(e, { context: "INTUIT_QUICKBOOKS:DISCOVER:LOOP_EXCEPTION", type: "error" })
          next
        end
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "INTUIT_QUICKBOOKS:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        @connector_instance = sync_config&.source&.connector_instance
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        access_token = create_connection(connection_config)
        query(access_token, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "INTUIT_QUICKBOOKS:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def query(access_token, query)
        parsed = batched_query_for_quickbooks(query)
        base_query = parsed[:base_query]
        limit = parsed[:limit]
        offset = parsed[:offset]
        execute_query(access_token, base_query, limit, offset).map do |r|
          flat_data = flatten_hash(r)
          RecordMessage.new(data: flat_data, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def execute_query(access_token, base_query, limit, offset)
        total_fetched = 0
        current_offset = offset
        result = []

        while total_fetched < limit
          batch_limit = [MAX_PER_PAGE, limit - total_fetched].min
          paginated_query = "#{base_query} STARTPOSITION #{current_offset + 1} MAXRESULTS #{batch_limit}"

          response = query_quickbooks(access_token, paginated_query)
          records = JSON.parse(response.body)["QueryResponse"] || {}

          break if records.empty?

          records.each_value do |rows|
            next unless rows.is_a?(Array)

            rows.each do |row|
              result << row
            end
          end

          fetched_count = result.size - total_fetched
          break if fetched_count < batch_limit

          total_fetched += fetched_count
          current_offset += fetched_count
        end
        result
      end

      def query_quickbooks(access_token, query)
        encoded_query = URI.encode_www_form_component(query)
        query_url = @environment == "sandbox" ? QUICKBOOKS_SANDBOX_QUERY_URL : QUICKBOOKS_PRODUCTION_QUERY_URL
        send_request(
          url: build_url(query_url, encoded_query),
          http_method: HTTP_GET,
          payload: {},
          headers: auth_headers(access_token),
          config: {}
        )
      end

      def create_connection(connection_config)
        load_connection_config(connection_config)
        refresh_access_token
      end

      def load_connection_config(connection_config)
        @client_id = connection_config[:client_id]
        @client_secret = connection_config[:client_secret]
        @realm_id = connection_config[:realm_id]
        @environment = connection_config[:environment]
        @refresh_token = if @connector_instance&.configuration
                           @connector_instance.configuration["refresh_token"]
                         else
                           connection_config[:refresh_token]
                         end
      end

      def refresh_access_token
        oauth2_client = IntuitOAuth::Client.new(@client_id, @client_secret, QUICKBOOKS_REDIRECT_URL, @environment)
        response = oauth2_client.token.refresh_tokens(@refresh_token)
        if @connector_instance&.configuration
          config = @connector_instance.configuration
          config = {} unless config.is_a?(Hash)
          new_config = config.merge("refresh_token" => response.refresh_token)
          @connector_instance.update!(configuration: new_config)
        end
        response.access_token
      end

      def create_streams(records)
        group_by_table(records).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r[:table_name], action: StreamAction["fetch"], json_schema: convert_to_json_schema(r[:columns]))
        end
      end

      def group_by_table(records)
        records.filter_map do |table_name, rows|
          if rows.is_a?(Array) && rows.all? { |row| row.is_a?(Hash) }
            row_sample = rows.first || {}
            columns = row_sample.map do |key, value|
              {
                column_name: key,
                data_type: normalize_type(value),
                is_nullable: rows.any? { |row| row[key].nil? }
              }
            end
            { table_name: table_name, columns: columns }
          end
        end
      end

      def batched_query_for_quickbooks(query)
        query = query.strip.chomp(";")
        limit = query[/LIMIT\s+(\d+)/i, 1] || 1000
        offset = query[/OFFSET\s+(\d+)/i, 1]

        base_query = query.gsub(/LIMIT\s+\d+/i, "").gsub(/OFFSET\s+\d+/i, "").strip
        {
          base_query: base_query,
          limit: limit.to_i,
          offset: offset.to_i
        }
      end

      def flatten_hash(hash, parent_key = "", result = {})
        hash.each do |key, value|
          full_key = parent_key.empty? ? key.to_s : "#{parent_key}.#{key}"

          case value
          when Hash
            flatten_hash(value, full_key, result)
          when Array
            next
          else
            result[full_key] = value.is_a?(Integer) || value.is_a?(Float) ? value : value.to_s
          end
        end
        result
      end

      def normalize_type(value)
        case value
        when Integer, Float then "NUMBER"
        else "string"
        end
      end

      def load_catalog
        read_json(CATALOG_SPEC_PATH)
      end

      def build_url(url, query)
        format(url, realm_id: @realm_id, query: query)
      end
    end
  end
end
