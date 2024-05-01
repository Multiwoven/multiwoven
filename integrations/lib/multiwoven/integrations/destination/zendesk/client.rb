# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Zendesk
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::RateLimiter
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            handle_exception("ZENDESK:CHECK_CONNECTION:EXCEPTION", "error", e)
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception("ZENDESK:DISCOVER:EXCEPTION", "error", e)
            failure_status(e)
          end

          def write(sync_config, records, action = "create")
            @action = sync_config.stream.action || action
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception("ZENDESK:WRITE:EXCEPTION", "error", e)
            failure_status(e)
          end

          private

          def initialize_client(connection_config)
            connection_config = connection_config.with_indifferent_access
            @client = ZendeskAPI::Client.new do |config|
              config.url = "#{connection_config[:subdomain]}.#{ZENDESK_URL_SUFFIX}"
              config.username = connection_config[:username]
              config.password = connection_config[:password]
            end
          end

          def authenticate_client
            response = @client.tickets.page(1).per_page(1).fetch

            raise StandardError, "Failed to authenticate with Zendesk: #{response.errors.join(", ")}" unless response.is_a?(Array) && !response.empty?
          rescue ZendeskAPI::Error => e
            raise StandardError, "Authentication failed: #{e.message}"
          end

          def process_records(records, stream)
            success_count = 0
            failure_count = 0

            records.each do |record|
              zendesk_data = prepare_record_data(record, stream.name)
              plural_stream_name = pluralize_stream_name(stream.name.downcase)

              response = if @action == "create"
                           @client.send(plural_stream_name).create!(zendesk_data)
                         else
                           existing_record = @client.send(plural_stream_name).find(id: record[:id])
                           existing_record.update!(zendesk_data)
                         end

              raise StandardError, "Failed to process record: #{response.errors.join(", ")}" unless response.save

              success_count += 1
            rescue ZendeskAPI::Error => e
              handle_exception("ZENDESK:WRITE_RECORD:EXCEPTION", "error", e)
              failure_count += 1
            end

            { success: success_count, failures: failure_count }
          end

          def pluralize_stream_name(name)
            { "ticket" => "tickets", "user" => "users" }.fetch(name, name)
          end

          def prepare_record_data(record, type)
            case type
            when "Tickets"
              {
                subject: record[:subject],
                comment: { body: record[:description] },
                priority: record[:priority],
                status: record[:status],
                requester_id: record[:requester_id],
                assignee_id: record[:assignee_id],
                tags: record[:tags]
              }
            when "Users"
              {
                name: record[:name],
                email: record[:email],
                role: record[:role]
              }
            else
              raise StandardError, "Unsupported record type: #{type}"
            end
          end

          def success_status
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
          end

          def failure_status(error)
            ConnectionStatus.new(status: ConnectionStatusType["failed"], message: error.message).to_multiwoven_message
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end
        end
      end
    end
  end
end
