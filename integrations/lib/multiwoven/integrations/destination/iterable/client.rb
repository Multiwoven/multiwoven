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
            write_success = 0
            write_failure = 0
            records.each do |record_object|
              record = extract_data(record_object, stream.json_schema[:properties])
              response = process_stream(record, stream)
              if response.success?
                write_success += 1
              else
                write_failure += 1
              end
            rescue StandardError => e
              handle_exception("ITERABLE:WRITE:EXCEPTION", "error", e)
              write_failure += 1
            end
            tracking_message(write_success, write_failure)
          end

          def process_stream(record, stream)
            klass = ::Iterable.const_get(stream.name).new(*initialize_params(stream, record))
            item_attrs = initialize_attribute(stream, record)
            if stream.name == "CatalogItems"
              klass.send(@action, item_attrs)
            else
              klass.send(@action)
            end
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

          def tracking_message(success, failure)
            Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: success, failed: failure
            ).to_multiwoven_message
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end
        end
      end
    end
  end
end
