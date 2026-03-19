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

        # Add filters if present
        filters = vector_search_config[:filters] || vector_search_config.filters || []
        body[:filter] = build_qdrant_filter(filters) if filters.present?

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

      def build_qdrant_filter(filters)
        return nil if filters.blank?

        must_conditions = []
        must_not_conditions = []

        filters.each do |filter|
          process_qdrant_filter(filter, must_conditions, must_not_conditions)
        end

        build_qdrant_filter_hash(must_conditions, must_not_conditions)
      end

      def process_qdrant_filter(filter, must_conditions, must_not_conditions)
        field, operator, value = extract_filter_fields(filter)
        return unless field.present? && value.present?

        condition = build_qdrant_condition(field, operator, value)
        return unless condition

        add_condition_to_array(condition, operator, must_conditions, must_not_conditions)
      end

      def extract_filter_fields(filter)
        [
          filter[:field] || filter["field"],
          filter[:operator] || filter["operator"] || "eq",
          filter[:value] || filter["value"]
        ]
      end

      def add_condition_to_array(condition, operator, must_conditions, must_not_conditions)
        if operator.to_s == "neq"
          must_not_conditions << condition
        else
          must_conditions << condition
        end
      end

      def build_qdrant_condition(field, operator, value)
        case operator.to_s
        when "eq"
          { key: field, match: { value: value } }
        when "neq"
          { key: field, match: { value: value } }
        when "gt"
          { key: field, range: { gt: value } }
        when "gte"
          { key: field, range: { gte: value } }
        when "lt"
          { key: field, range: { lt: value } }
        when "lte"
          { key: field, range: { lte: value } }
        when "in"
          { key: field, match: { any: value.is_a?(Array) ? value : [value] } }
        end
      end

      def build_qdrant_filter_hash(must_conditions, must_not_conditions)
        qdrant_filter = {}
        qdrant_filter[:must] = must_conditions if must_conditions.present?
        qdrant_filter[:must_not] = must_not_conditions if must_not_conditions.present?

        qdrant_filter.presence
      end
    end
  end
end
