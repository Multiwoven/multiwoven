module Multiwoven
    module Integrations
        module Destination
            module Zendesk
                include Multiwoven::Integrations::Core

                API_VERSION = "59.0"

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

                    def write(sync_config, tickets, action = "create")
                        @action = sync_config.stream.action || action
                        initialize_client(sync_config.destination.connection_specification)
                        process_tickets(tickets, sync_config.stream)
                        rescue StandardError => e
                            handle_exception("ZENDESK:WRITE:EXCEPTION", "error", e)
                            failure_status(e)
            
                    end
                    private

                    def initialize_client(connection_config)
                        connection_config = connection_config.with_indifferent_access
                        @client = ZendeskAPI::Client.new do |config|
                            config.url = ZENDESK_TICKETING_URL
                            config.username = connection_config[:username]
                            config.password = connection_config[:password]
                        end
                    end

                    def authenticate_client
                        response = @client.tickets.page(1).per_page(1).fetch
                        
                        # response should return an array of Ticket objs
                        if response.is_a?(Array) && !response.empty?
                            true
                        else
                          raise StandardError, "Failed to authenticate with Zendesk: #{response.errors.join(", ")}"
                        end
                      rescue ZendeskAPI::Error => e
                        raise StandardError, "Authentication failed: #{e.message}"
                    end
                    
                    def process_tickets(tickets, stream)
                        write_success = 0
                        write_failure = 0
                        properties = stream.json_schema[:properties]
                        tickets.each do |ticket_object|
                        ticket = extract_data(ticket_object, properties)
                        klass  = @client.const_get(stream.name)
                        klass.send(@action, ticket)
                        write_success += 1
                        rescue StandardError => e
                            handle_exception("ZENDESK:WRITE:EXCEPTION", "error", e)
                            write_failure += 1
                        end
                        tracking_message(write_success, write_failure)
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

                    def tracking_message(success, failure)
                        Multiwoven::Integrations::Protocol::TrackingMessage.new(
                          success: success, failed: failure
                        ).to_multiwoven_message
                    end
                end
            end
        end
    end
end