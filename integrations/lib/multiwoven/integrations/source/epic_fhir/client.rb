# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module EpicFhir
    include Multiwoven::Integrations::Core

    FHIR_ACCEPT = "application/fhir+json"
    NDJSON_ACCEPT = "application/fhir+ndjson"
    DEFAULT_EXPORT_POLL_INTERVAL = 5
    DEFAULT_EXPORT_TIMEOUT = 120
    REQUIRED_CONFIG_KEYS = %w[fhir_base_url token_url client_id private_key kid export_group_id].freeze
    DEFAULT_RESOURCES = %w[
      AllergyIntolerance
      Appointment
      CarePlan
      CareTeam
      Condition
      Consent
      Device
      DiagnosticReport
      DocumentReference
      Encounter
      EpisodeOfCare
      Goal
      Immunization
      List
      MedicationRequest
      Observation
      Patient
      Procedure
      ServiceRequest
    ].freeze

    class Client < SourceConnector
      include Multiwoven::Integrations::Core::OauthClientCredentials

      def check_connection(connection_config)
        connection_config = prepare_config(connection_config)
        validate_config!(connection_config)
        build_headers(connection_config)
        success_status
      rescue StandardError => e
        handle_exception(e, {
                           context: "EPIC_FHIR:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = prepare_config(connection_config)
        validate_config!(connection_config)
        streams = discover_resource_types(connection_config).map { |resource_type| create_stream(resource_type) }

        Catalog.new(streams: streams).to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "EPIC_FHIR:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = prepare_config(sync_config&.source&.connection_specification)
        validate_config!(connection_config)
        @connector_instance = sync_config&.source&.connector_instance

        sql_query = sync_config.model.query
        sql_query = batched_query(sql_query, sync_config.limit, sync_config.offset) if
          sync_config.limit.present? || sync_config.offset.present?
        query(connection_config, sql_query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "EPIC_FHIR:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def prepare_config(config)
        config = config.to_unsafe_h if config.respond_to?(:to_unsafe_h)
        config = {} unless config.is_a?(Hash)
        config.with_indifferent_access.tap do |conf|
          conf[:auth_type] = AUTH_TYPE_PRIVATE_KEY_JWT
          conf[:fhir_base_url] = conf[:fhir_base_url].to_s.sub(%r{/+\z}, "")
        end
      end

      def validate_config!(config)
        missing = REQUIRED_CONFIG_KEYS.reject { |key| config[key].to_s.strip.present? }
        raise ArgumentError, "Missing required Epic FHIR configuration: #{missing.join(", ")}" if missing.any?

        validate_export_timeout!(config)
      end

      def validate_export_timeout!(config)
        raw = config[:export_timeout]
        return if raw.to_s.strip.empty?

        value = raw.to_f
        raise ArgumentError, "Export timeout must be greater than 0" unless value.positive?
        return if value <= DEFAULT_EXPORT_TIMEOUT

        raise ArgumentError,
              "Export timeout must be equal to or less than #{DEFAULT_EXPORT_TIMEOUT}"
      end

      # Model preview passes this value back into #query.
      def create_connection(connection_config)
        prepare_config(connection_config)
      end

      def query(connection_config, sql_query)
        connection_config = prepare_config(connection_config)
        validate_config!(connection_config)
        resource_type, limit, offset = parse_sql_query(sql_query)

        bulk_export_resources(connection_config, resource_type, limit: limit, offset: offset).map do |resource|
          RecordMessage.new(data: displayable_resource(resource), emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def displayable_resource(resource)
        resource.to_h.transform_values do |value|
          value.is_a?(Hash) || value.is_a?(Array) ? JSON.generate(value) : value
        end
      end

      def discover_resource_types(connection_config)
        configured = configured_resources(connection_config)
        configured.any? ? configured : DEFAULT_RESOURCES
      end

      def configured_resources(connection_config)
        raw = connection_config[:resources]
        values = raw.is_a?(Array) ? raw : raw.to_s.split(",")
        values.map(&:to_s).map(&:strip).reject(&:empty?).select { |value| valid_resource_type?(value) }
      end

      def create_stream(resource_type)
        Multiwoven::Integrations::Protocol::Stream.new(
          name: resource_type,
          action: StreamAction["fetch"],
          json_schema: base_resource_schema,
          supported_sync_modes: %w[full_refresh],
          source_defined_primary_key: [["id"]]
        )
      end

      # Shared across resource types: FHIR Resource / DomainResource keys are
      # always present (nested values become JSON strings in #displayable_resource).
      # Type-specific fields (e.g. Patient.name) also appear at read time, so the
      # schema allows additional string properties instead of pretending the
      # catalog only has id + resourceType.
      def base_resource_schema
        schema = convert_to_json_schema(
          %w[
            id
            resourceType
            meta
            implicitRules
            language
            text
            contained
            extension
            modifierExtension
          ].map { |column_name| { column_name: column_name, type: "string" } }
        )
        schema["additionalProperties"] = true
        schema
      end

      # The manifest and records are cached for batched LIMIT/OFFSET reads during this client run.
      def bulk_export_resources(connection_config, resource_type, limit:, offset:)
        return [] if limit&.zero?

        @bulk_manifests ||= {}
        @bulk_records ||= {}

        key = [
          connection_config[:fhir_base_url],
          connection_config[:export_group_id],
          resource_type
        ]

        manifest = @bulk_manifests[key] ||= run_bulk_export(connection_config, resource_type)

        records = @bulk_records[key] ||= bulk_output_urls(manifest, resource_type).flat_map do |url|
          download_ndjson(connection_config, url)
        end

        apply_limit_offset(records, limit: limit, offset: offset)
      end

      def apply_limit_offset(records, limit:, offset:)
        start = offset.to_i
        return records.drop(start) if limit.nil?

        records[start, limit] || []
      end

      def run_bulk_export(connection_config, resource_type)
        status_url = kickoff_bulk_export(connection_config, resource_type)
        poll_bulk_export(connection_config, status_url)
      end

      def kickoff_bulk_export(connection_config, resource_type)
        url = bulk_export_url(connection_config, resource_type)
        response = fhir_get(connection_config, url, extra_headers: { "Prefer" => "respond-async" })
        raise fhir_api_error(response, url) unless response.code.to_s == "202"

        status_url = response["content-location"].presence
        raise StandardError, "Epic FHIR 202 #{url} missing Content-Location header" if status_url.nil?

        status_url
      end

      def poll_bulk_export(connection_config, status_url)
        timeout = export_timeout(connection_config)
        deadline = Time.now + timeout

        loop do
          response = fhir_get(connection_config, status_url)
          code = response.code.to_s
          return JSON.parse(response.body) if code == "200"
          raise fhir_api_error(response, status_url) unless code == "202"
          raise StandardError, "Epic FHIR 202 #{status_url} still in progress after #{timeout}s" if Time.now >= deadline

          sleep(retry_after(response) || export_poll_interval(connection_config))
        end
      end

      def download_bulk_output(connection_config, manifest, resource_type, limit:, offset:)
        return [] if limit&.zero?

        records = []
        pending_offset = offset.to_i

        bulk_output_urls(manifest, resource_type).each do |url|
          resources = download_ndjson(connection_config, url)
          skipped = [pending_offset, resources.size].min
          pending_offset -= skipped
          records.concat(resources.drop(skipped))
          break if limit_reached?(records, limit)
        end

        limit_reached?(records, limit) ? records.first(limit) : records
      end

      def bulk_output_urls(manifest, resource_type)
        Array(manifest["output"]).filter_map do |entry|
          entry["url"].presence if entry.is_a?(Hash) && entry["type"].to_s == resource_type
        end
      end

      def download_ndjson(connection_config, url)
        response = fhir_get(connection_config, url, accept: NDJSON_ACCEPT)
        raise fhir_api_error(response, url) unless success?(response)

        parse_ndjson(response.body)
      end

      def parse_ndjson(body)
        body.to_s.each_line.with_index(1).filter_map do |line, line_number|
          line = line.strip
          next if line.empty?

          JSON.parse(line)
        rescue JSON::ParserError => e
          raise StandardError, "Error parsing NDJSON: #{e.message} at line #{line_number}: #{line}"
        end
      end

      # Epic serves Bulk Data only from Group level; there is no system-level $export.
      def bulk_export_url(connection_config, resource_type)
        group_id = connection_config[:export_group_id].to_s.strip
        base = "#{connection_config[:fhir_base_url]}/Group/#{group_id}/$export"
        params = { "_type" => resource_type }
        since = connection_config[:export_since].to_s.strip
        params["_since"] = since if since.present?
        "#{base}?#{URI.encode_www_form(params)}"
      end

      def retry_after(response)
        value = response["retry-after"].to_s.strip
        delay = value.to_i if value.match?(/\A\d+\z/)
        delay if delay&.positive?
      end

      def export_poll_interval(connection_config)
        interval = numeric_setting(connection_config[:export_poll_interval], DEFAULT_EXPORT_POLL_INTERVAL)
        interval.finite? && interval.positive? ? interval : DEFAULT_EXPORT_POLL_INTERVAL
      end

      def export_timeout(connection_config)
        numeric_setting(connection_config[:export_timeout], DEFAULT_EXPORT_TIMEOUT)
      end

      def numeric_setting(raw, default)
        return default if raw.to_s.strip.empty?

        value = raw.to_f
        value.negative? ? default : value
      end

      def limit_reached?(records, limit)
        !limit.nil? && records.size >= limit
      end

      def parse_sql_query(sql_query)
        query = sql_query.to_s.strip.chomp(";")
        resource_type = query[/FROM\s+([^\s;]+)/i, 1]
        raise ArgumentError, "Could not extract FHIR resource type from query" if resource_type.blank?
        raise ArgumentError, "Invalid FHIR resource type: #{resource_type}" unless valid_resource_type?(resource_type)

        limit = query[/LIMIT\s+(\d+)/i, 1]&.to_i
        offset = query[/OFFSET\s+(\d+)/i, 1]&.to_i
        [resource_type, limit, offset]
      end

      def valid_resource_type?(resource_type)
        resource_type.match?(/\A[A-Z][A-Za-z0-9]*\z/)
      end

      def fhir_get(connection_config, url, extra_headers: {}, accept: FHIR_ACCEPT)
        Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_GET,
          headers: fhir_headers(connection_config, accept: accept).merge(extra_headers),
          options: { config: connection_config[:config] || {} }
        )
      end

      def fhir_headers(connection_config, accept: FHIR_ACCEPT)
        headers = build_headers(connection_config).transform_keys(&:to_s)
        headers["Accept"] = accept
        headers
      end

      def fhir_api_error(response, url = nil)
        body = response.respond_to?(:body) ? response.body.to_s : response.to_s
        code = response.respond_to?(:code) ? response.code.to_s : "unknown"
        StandardError.new(["Epic FHIR", code, url, body].map(&:to_s).reject(&:empty?).join(" "))
      end
    end
  end
end
