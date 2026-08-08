# frozen_string_literal: true

require "sequel"
require "multiwoven/integrations/core/source_connector"
require "multiwoven/integrations/protocol/protocol"
require "active_support/core_ext/hash/indifferent_access"

module Multiwoven
  module Integrations
    module Source
      module MysqlDb
        class Client < Multiwoven::Integrations::Core::SourceConnector
          def check_connection(connection_config)
            db = create_connection(connection_config.with_indifferent_access)
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
          rescue StandardError => e
            ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
          ensure
            db&.disconnect
          end

          def discover(connection_config)
            cfg = connection_config.with_indifferent_access
            db = create_connection(cfg)

            results = db[:information_schema__columns]
                      .where(table_schema: cfg[:database])
                      .order(:table_name, :ordinal_position)
                      .select(:table_name, :column_name, :data_type, :is_nullable)
                      .all

            catalog = Catalog.new(streams: build_streams(results))
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, context: "MYSQL:DISCOVER:EXCEPTION", type: "error")
          ensure
            db&.disconnect
          end

          def read(sync_config)
            cfg = sync_config.source.connection_specification.with_indifferent_access
            db = create_connection(cfg)

            sql = sync_config.model.query
            sql = batched_query(sql, sync_config.limit, sync_config.offset) if sync_config.limit || sync_config.offset

            rows = db.fetch(sql)
            rows.map do |row|
              RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
            end
          rescue StandardError => e
            handle_exception(e, {
                               context: "MYSQL:READ:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
          ensure
            db&.disconnect
          end

          private

          def create_connection(cfg)
            Sequel.connect(
              adapter: "mysql2",
              host: cfg[:host],
              port: cfg[:port] || 3306,
              user: cfg[:username],
              password: cfg[:password],
              database: cfg[:database]
            )
          end

          def build_streams(records)
            records.group_by { |r| r[:table_name] || r[:TABLE_NAME] }.map do |table_name, cols|
              schema = convert_schema(cols)
              Multiwoven::Integrations::Protocol::Stream.new(
                name: table_name.to_s,
                action: StreamAction["fetch"],
                json_schema: schema
              )
            end
          end

          def convert_schema(columns)
            properties = {}

            columns.each do |col|
              col_name = col[:column_name] || col[:COLUMN_NAME]
              data_type = col[:data_type] || col[:DATA_TYPE]

              properties[col_name] = { type: map_type(data_type) }
            end

            { type: "object", properties: properties }
          end

          def query(db, query)
            rows = db.fetch(query)
            rows.map do |row|
              RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
            end
          end

          def map_type(data_type)
            case data_type
            when /int/ then "integer"
            when /char|text|varchar/ then "string"
            when /date|time|timestamp/ then "string"
            when /decimal|float|double/ then "number"
            when /bool/ then "boolean"
            else "string"
            end
          end
        end
      end
    end
  end
end
