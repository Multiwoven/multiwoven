# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Http
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = prepare_config(connection_config)
        create_connection(connection_config)
        if connection_config[:sample_query].blank?
          build_paginated_request(connection_config, {})
        else
          sample_query = JSON.parse(connection_config[:sample_query])
          build_paginated_request(connection_config, sample_query.values.first)
        end
        response = send_request(
          url: @url,
          http_method: connection_config[:http_method],
          payload: connection_config[:request_format],
          headers: connection_config[:headers],
          config: connection_config[:config],
          params: connection_config[:params]
        )
        success?(response) ? success_status : failure_status(nil)
      rescue StandardError => e
        handle_exception(e, { context: "HTTP:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = prepare_config(connection_config)
        create_connection(connection_config)
        if connection_config[:sample_query].blank?
          build_paginated_request(connection_config, {})
        else
          sample_query = JSON.parse(connection_config[:sample_query])
          build_paginated_request(connection_config, sample_query.values.first)
        end
        response = send_request(
          url: @url,
          http_method: connection_config[:http_method],
          payload: connection_config[:request_format],
          headers: connection_config[:headers],
          config: connection_config[:config],
          params: connection_config[:params]
        )
        raise StandardError, "Response code: #{response.code}, Body: #{response.body}" unless success?(response)

        catalog = Catalog.new(streams: create_streams(JSON.parse(response.body)))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "HTTP:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        connection_config = create_connection(connection_config)
        if sync_config.increment_strategy_config.increment_strategy == "page"
          @limit = sync_config.increment_strategy_config.limit
          @offset = sync_config.increment_strategy_config.offset
        else
          @limit = sync_config.limit
          @offset = sync_config.offset
        end
        query = sync_config.model.query
        query(connection_config, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "HTTP:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def prepare_config(config)
        config.with_indifferent_access.tap do |conf|
          conf[:config][:timeout] ||= 30
        end
      end

      def create_connection(connection_config)
        @url = "#{connection_config[:base_url]}#{connection_config[:path]}"
        connection_config
      end

      def build_paginated_request(connection_config, query)
        connection_config[:request_format] = JSON.parse(connection_config[:request_format] || "{}")

        apply_param_pagination(connection_config)
        apply_batched_query(connection_config, query)
      end

      def apply_param_pagination(connection_config)
        return unless connection_config[:limit_param].present? && connection_config[:offset_param].present?

        connection_config[:params] = {} if connection_config[:params].nil?
        connection_config[:params].merge!({ connection_config[:limit_param] => @limit }) if @limit.present?
        connection_config[:params].merge!({ connection_config[:offset_param] => @offset }) if @offset.present?
      end

      def apply_batched_query(connection_config, query)
        return unless connection_config[:sample_query].present?

        sample_query = JSON.parse(connection_config[:sample_query])
        query = batched_query(query, @limit, @offset) unless @limit.nil? && @offset.nil?
        connection_config[:request_format].merge!({ sample_query.keys.first => query }) unless query.nil?
      end

      def query(connection_config, query)
        connection_config = prepare_config(connection_config)
        build_paginated_request(connection_config, query)
        response = send_request(
          url: @url,
          http_method: connection_config[:http_method],
          payload: connection_config[:request_format],
          headers: connection_config[:headers],
          config: connection_config[:config],
          params: connection_config[:params] || {}
        )
        if success?(response)
          response_body = JSON.parse(response.body)
          parse_response = get_parse_response(connection_config[:parse_response])
          parse_response(response_body, parse_response)
        else
          handle_exception("Failed to fetch data", { context: "HTTP:QUERY:EXCEPTION", type: "error" })
        end
      end

      def create_streams(response_body)
        group_by_table(response_body).map do |r|
          Multiwoven::Integrations::Protocol::Stream.new(name: r["name"], action: StreamAction["fetch"], json_schema: r["schema"])
        end
      end

      def get_parse_response(parse_response)
        parse_response = JSON.parse(parse_response) if parse_response.is_a?(String) && parse_response.start_with?("[")
        parse_response
      end

      def parse_response(response_body, parse_response)
        case parse_response
        when Array
          records = []
          parse_response.each do |path|
            records << JsonPath.on(response_body, path)
          end
          records[1].each_slice(records[0].size).map do |row_values|
            data = Hash[records[0].zip(row_values)]
            RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message
          end
        else
          records = JsonPath.on(response_body, parse_response)
          records.map do |data|
            RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message
          end
        end
      end

      def build_schema(record)
        case record
        when Hash
          {
            "type" => "object",
            "properties" => record.transform_values { |value| build_schema(value) }
          }
        when Array
          {
            "type" => "array",
            "items" => build_schema(record.first)
          }
        else
          { "type" => %w[string null] }
        end
      end

      def group_by_table(response_body)
        schema = []
        response_body.each do |key, values|
          schema << {
            "name" => key.to_s,
            "schema" => {
              "$schema" => "http://json-schema.org/draft-07/schema#",
              "type" => "object",
              "properties" => {
                key.to_s => build_schema(values)
              }
            }
          }
        end
        schema
      end
    end
  end
end
