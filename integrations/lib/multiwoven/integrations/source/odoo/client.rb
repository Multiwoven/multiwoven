# frozen_string_literal: true

require "xmlrpc/client"

module Multiwoven::Integrations::Source
  module Odoo
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
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

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        create_connection(connection_config)
        query = sync_config.model.query
        query(connection_config, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "ODOO:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

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
        fields.each do |field|
          column_name = field[1]["name"]
          type = field[1]["type"]
          json_schema["properties"][column_name] = {
            "type" => type
          }
        end
        json_schema
      end

      def create_connection(connection_config)
        common = XMLRPC::Client.new2("#{connection_config[:url]}/xmlrpc/2/common")
        common.call("version")
        @uid = common.call("authenticate", connection_config[:database], connection_config[:username],
                           connection_config[:password], { 'raise_exception': true })
        @client = XMLRPC::Client.new2("#{connection_config[:url]}/xmlrpc/2/object").proxy
        connection_config
      end

      def query(connection, query)
        limit = 0
        limit = query.match(/LIMIT (\d+)/)[1].to_i if query.include? "LIMIT"

        model = query.gsub(/LIMIT\s+\d+/i, "").gsub(/SELECT (.*) FROM/, "").strip
        columns = if query.include? "SELECT *"
                    []
                  else
                    query.match(/SELECT (.*) FROM/)[1].strip.downcase.split(", ")
                  end

        records = @client.execute_kw(connection[:database], @uid, connection[:password],
                                     model, "search_read", [], { limit: limit, 'fields': columns })
        records.map do |row|
          puts row
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end
    end
  end
end
