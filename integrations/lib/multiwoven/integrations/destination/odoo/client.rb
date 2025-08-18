# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Odoo
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        success_status
      rescue StandardError => e
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)

        models = @client.execute_kw(connection_config[:database], @uid, connection_config[:password],
                                    "ir.model", "search_read", [[["transient", "=", false], ["abstract", "=", false]]], { 'fields': %w[name model] })

        catalog = Catalog.new(streams: create_streams(connection_config, models))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "ODOO:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "destination_insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        create_connection(connection_config)
        model = sync_config.stream.name

        write_success = 0
        write_failure = 0
        log_message_array = []

        records.each do |record|
          logger.debug("ODOO:WRITE:#{model} sync_id = #{sync_config.sync_id} sync_run_id = #{sync_config.sync_run_id}")
          begin
            record = format_record(record, sync_config.stream.json_schema)
            response = @client.execute_kw(connection_config[:database], @uid, connection_config[:password],
                                          model, "create", [record])
            write_success += 1
            log_message_array << log_request_response("info", model, response)
          rescue StandardError => e
            handle_exception(e, {
                               context: "ODOO:WRITE:#{model}",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
            write_failure += 1
            log_message_array << log_request_response("error", model, e.message)
          end
        end
        tracking_message(write_success, write_failure, log_message_array)
      rescue StandardError => e
        handle_exception(e, {
                           context: "ODOO:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def format_record(record, json_schema)
        json_schema = json_schema.with_indifferent_access
        properties = json_schema["properties"]
        record.each_key do |key|
          data_type = properties[key]["type"]
          record[key] = record[key].to_i if data_type == "many2one"
          record[key] = JSON.parse(record[key]) if data_type == "one2many"
        end
        record
      end

      def create_streams(connection_config, models)
        models.map do |model|
          fields = @client.execute_kw(connection_config[:database], @uid, connection_config[:password],
                                      model["model"], "fields_get", [], { 'attributes': %w[name type] })
          Multiwoven::Integrations::Protocol::Stream.new(name: model["model"], action: StreamAction["fetch"],
                                                         supported_sync_modes: %w[incremental], json_schema: convert_to_json_schema(fields))
        end
      end

      def convert_to_json_schema(fields)
        json_schema = {
          "type" => "object",
          "properties" => {}
        }
        required_fields = []
        fields.each do |field|
          next if field[1]["readonly"]

          column_name = field[1]["name"]
          required = field[1]["required"]
          type = field[1]["type"]
          json_schema["properties"][column_name] = {
            "type" => type
          }
          required_fields.push(column_name) if required
        end
        json_schema["required"] = required_fields
        json_schema
      end

      def create_connection(connection_config)
        common = XMLRPC::Client.new2("#{connection_config[:url]}/xmlrpc/2/common")
        common.call("version")
        @uid = common.call("authenticate", connection_config[:database], connection_config[:username],
                           connection_config[:password], { 'raise_exception': true })
        @client = XMLRPC::Client.new2("#{connection_config[:url]}/xmlrpc/2/object").proxy
      end
    end
  end
end
