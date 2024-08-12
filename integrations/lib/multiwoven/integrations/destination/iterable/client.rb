# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Iterable
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector
          MAX_CHUNK_SIZE = 10
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            channels = ::Iterable::Channels.new
            response = channels.all
            if response.success?
              success_status
            else
              failure_status(nil)
            end
          rescue StandardError => e
            handle_exception(e, {
                               context: "ITERABLE:CHECK_CONNECTION:EXCEPTION",
                               type: "error"
                             })
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(
              "ITERABLE:DISCOVER:EXCEPTION",
              "error",
              e
            )
          end

          def write(sync_config, records, action = "create")
            @action = sync_config.stream.action || action
            connection_config = sync_config.destination.connection_specification.with_indifferent_access
            initialize_client(connection_config)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception("ITERABLE:WRITE:EXCEPTION", "error", e)
          end

          private

          def initialize_client(connection_config)
            ::Iterable.configure do |config|
              config.token = connection_config[:api_key]
            end
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            records.each do |record_object|
              record = extract_data(record_object, stream.json_schema[:properties])
              request, response = *process_stream(record, stream)
              if response.success?
                write_success += 1
              else
                write_failure += 1
              end
              log_message_array << log_request_response("info", request, response.body)
            rescue StandardError => e
              handle_exception("ITERABLE:WRITE:EXCEPTION", "error", e)
              write_failure += 1
              log_message_array << log_request_response("error", request, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def process_stream(record, stream)
            klass = ::Iterable.const_get(stream.name).new(*initialize_params(stream, record))
            item_attrs = initialize_attribute(stream, record)
            response = if stream.name == "CatalogItems"
                         klass.send("create", item_attrs)
                       else
                         klass.send("create")
                       end
            [item_attrs, response]
          end

          def initialize_params(stream, record)
            if stream.name == "CatalogItems"
              [record[:catalog_name], record[:item_id]]
            else
              [record[:catalog]]
            end
          end

          def initialize_attribute(stream, record)
            if stream.name == "CatalogItems"
              JSON.parse(record[:item_attribute])
            else
              {}
            end
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end
        end
      end
    end
  end
end
