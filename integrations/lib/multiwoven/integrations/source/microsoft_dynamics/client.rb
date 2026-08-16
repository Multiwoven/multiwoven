# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module MicrosoftDynamics
    include Multiwoven::Integrations::Core

    API_VERSION = "9.2"
    EXPIRED_ACCESS_TOKEN_ERROR_CODE = "InvalidAuthenticationToken"
    # Dynamics Web API max page size; $skip is not supported, so paging uses @odata.nextLink.
    PAGE_SIZE = 5000
    DYNAMICS_OBJECTS = %w[accounts contacts opportunities leads].freeze
    ENTITY_ORDER_BY = {
      "accounts" => "accountid",
      "contacts" => "contactid",
      "opportunities" => "opportunityid",
      "leads" => "leadid"
    }.freeze

    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        response = dynamics_request(whoami_url)
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

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)

        streams = DYNAMICS_OBJECTS.filter_map do |entity|
          create_stream_for_entity(entity)
        rescue StandardError => e
          handle_exception(e, {
                             context: "MICROSOFT:DYNAMICS:DISCOVER:LOOP_EXCEPTION",
                             type: "error"
                           })
          nil
        end

        Catalog.new(streams: streams).to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "MICROSOFT:DYNAMICS:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        @connector_instance = sync_config&.source&.connector_instance
        create_connection(connection_config)

        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        query(nil, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "MICROSOFT:DYNAMICS:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        load_connection_config(connection_config)
      end

      def load_connection_config(connection_config)
        @tenant_id = connection_config[:tenant_id]
        @client_id = connection_config[:application_id]
        @instance_url = connection_config[:instance_url]
        @client_secret = connection_config[:client_secret]
        stored_token = @connector_instance&.configuration&.dig("access_token")
        @access_token = stored_token.presence || refresh_access_token
      end

      def refresh_access_token
        @access_token = fetch_access_token
        persist_access_token(@access_token)
        @access_token
      end

      def persist_access_token(token)
        return unless @connector_instance&.configuration

        config = @connector_instance.configuration
        config = {} unless config.is_a?(Hash)
        @connector_instance.update!(configuration: config.merge("access_token" => token))
      end

      def fetch_access_token
        response = Multiwoven::Integrations::Core::HttpClient.request(
          format(MICROSOFT_GRAPH_TOKEN_URL, tenant_id: @tenant_id),
          HTTP_POST,
          payload: form_urlencoded_payload(
            client_id: @client_id,
            client_secret: @client_secret,
            scope: "https://#{@instance_url}.crm.dynamics.com/.default",
            grant_type: "client_credentials"
          ),
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded"
          }
        )
        raise dynamics_api_error(response.body) unless success?(response)

        JSON.parse(response.body)["access_token"]
      end

      def query(_connection, sql_query)
        entity, select_fields, limit, offset = parse_sql_query(sql_query)
        records = fetch_entity_records(entity, select_fields: select_fields, limit: limit, offset: offset)
        records.map do |row|
          RecordMessage.new(data: sanitize_record(row), emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def create_stream_for_entity(entity)
        records = fetch_entity_records(entity, limit: 1)
        raise StandardError, "No records found for #{entity}" if records.empty?

        columns = records.first.keys.reject { |key| odata_annotation?(key) }.map do |key|
          { column_name: key, type: "string" }
        end

        Multiwoven::Integrations::Protocol::Stream.new(
          name: entity,
          action: StreamAction["fetch"],
          json_schema: convert_to_json_schema(columns),
          supported_sync_modes: %w[incremental]
        )
      end

      def fetch_entity_records(entity, select_fields: nil, limit: nil, offset: nil)
        offset = offset.to_i
        limit = limit&.to_i
        records = []
        skipped = 0
        url = entity_url(
          entity,
          select_fields: select_fields,
          top: page_size_for(limit: limit, offset: offset)
        )

        while url.present?
          page_records, next_url = fetch_entity_page(url)
          break if page_records.empty?

          skipped = collect_page_records(
            records,
            page_records,
            offset: offset,
            limit: limit,
            skipped: skipped
          )
          break if limit_reached?(records, limit)

          url = next_url
        end

        records
      end

      def fetch_entity_page(url)
        response = dynamics_request(url)
        raise dynamics_api_error(response.body) unless success?(response)

        body = JSON.parse(response.body)
        [body["value"] || [], body["@odata.nextLink"]]
      end

      def collect_page_records(records, page_records, offset:, limit:, skipped:)
        page_records.each do |record|
          if skipped < offset
            skipped += 1
            next
          end

          records << record
          break if limit_reached?(records, limit)
        end
        skipped
      end

      def limit_reached?(records, limit)
        limit.present? && limit.positive? && records.size >= limit
      end

      def parse_sql_query(sql_query)
        query = sql_query.to_s.strip.chomp(";")
        entity = query[/FROM\s+([^\s;]+)/i, 1]
        raise ArgumentError, "Could not extract entity name from query" if entity.blank?

        select_clause = query[/SELECT\s+(.+?)\s+FROM/i, 1]
        select_fields = if select_clause.nil? || select_clause.strip == "*"
                          nil
                        else
                          select_clause.split(",").map(&:strip)
                        end

        limit = query[/LIMIT\s+(\d+)/i, 1]&.to_i
        offset = query[/OFFSET\s+(\d+)/i, 1]&.to_i

        [entity, select_fields, limit, offset]
      end

      # CRM rejects OData $skip ("Skip Clause is not supported").
      # Batching uses $top + @odata.nextLink, applying OFFSET in-process.
      def entity_url(entity, select_fields: nil, top: nil)
        entity = entity.to_s
        raise ArgumentError, "Invalid entity name: #{entity}" unless entity.match?(/\A\w+\z/)

        base = format(MS_DYNAMICS_REST_API, instance_url: @instance_url, api_version: API_VERSION, entity: entity)
        query_parts = []
        query_parts << "$select=#{URI.encode_www_form_component(select_fields.join(","))}" if select_fields.present?
        order_by = ENTITY_ORDER_BY[entity]
        query_parts << "$orderby=#{URI.encode_www_form_component(order_by)}" if order_by.present?
        query_parts << "$top=#{top.to_i}" if top.present? && top.to_i.positive?
        query_parts.empty? ? base : "#{base}?#{query_parts.join("&")}"
      end

      def page_size_for(limit:, offset:)
        offset = offset.to_i
        limit = limit&.to_i
        return [PAGE_SIZE, offset + limit].min if offset.positive? && limit.present? && limit.positive?
        return limit if limit.present? && limit.positive?

        PAGE_SIZE
      end

      def whoami_url
        format(MS_DYNAMICS_WHOAMI_API, instance_url: @instance_url, api_version: API_VERSION)
      end

      def dynamics_request(url)
        response = dynamics_http_get(url)
        return response unless expired_access_token_error?(response)

        refresh_access_token
        dynamics_http_get(url)
      end

      def dynamics_http_get(url)
        Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_GET,
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{@access_token}",
            "Content-Type" => "application/json"
          }
        )
      end

      def sanitize_record(record)
        record.each_with_object({}) do |(key, value), result|
          next if odata_annotation?(key)
          next if value.is_a?(Hash) || value.is_a?(Array)

          result[key] = value
        end
      end

      def odata_annotation?(key)
        key.to_s.start_with?("@") || key.to_s.include?("@odata")
      end

      def dynamics_api_error(response_body)
        parsed = JSON.parse(response_body)
        error = parsed["error"]

        message = if error.is_a?(Hash)
                    "#{error["code"]}: #{error["message"]}"
                  elsif error.is_a?(String)
                    description = parsed["error_description"]
                    description.present? ? "#{error}: #{description}" : error
                  else
                    response_body
                  end

        StandardError.new(message)
      rescue JSON::ParserError, TypeError
        StandardError.new(response_body.to_s)
      end

      def expired_access_token_error?(response)
        return true if response.code.to_s == "401"

        error = JSON.parse(response.body)["error"]
        return false unless error.is_a?(Hash)

        error["code"] == EXPIRED_ACCESS_TOKEN_ERROR_CODE
      rescue JSON::ParserError, TypeError
        false
      end

      # HttpClient.request always calls payload.to_json.
      # Microsoft OAuth token endpoints require
      # application/x-www-form-urlencoded bodies instead of JSON.
      # This wrapper overrides to_json so HttpClient sends a
      # form-encoded string rather than a JSON document.
      def form_urlencoded_payload(fields)
        payload = Object.new
        payload.define_singleton_method(:to_json) do |*_args|
          URI.encode_www_form(fields)
        end
        payload
      end
    end
  end
end
