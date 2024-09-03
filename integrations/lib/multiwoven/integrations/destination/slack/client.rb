# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Slack
        include Multiwoven::Integrations::Core

        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::RateLimiter
          attr_accessor :channel_id

          def check_connection(connection_config)
            configure_slack(connection_config[:api_token])
            client = ::Slack::Web::Client.new
            client.auth_test
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "SLACK:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, action = "create")
            # Currently as we only create a message for each record in slack, we are not using actions.
            # This will be changed in future.
            @sync_config = sync_config
            @action = sync_config.stream.action || action
            connection_config = sync_config.destination.connection_specification.with_indifferent_access
            configure_slack(connection_config[:api_token])
            @client = ::Slack::Web::Client.new
            @channel_id = connection_config[:channel_id]
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
                               context: "SLACK:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
          end

          private

          def configure_slack(api_token)
            ::Slack.configure do |config|
              config.token = api_token
            end
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            records.each do |record_object|
              request, response = *process_record(stream, record_object.with_indifferent_access)
              write_success += 1
              log_message_array << log_request_response("info", request, response)
            rescue StandardError => e
              write_failure += 1
              handle_exception(e, {
                                 context: "SLACK:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: @sync_config.sync_id,
                                 sync_run_id: @sync_config.sync_run_id
                               })
              log_message_array << log_request_response("error", request, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def process_record(stream, record)
            send_data_to_slack(stream[:name], record)
          end

          def send_data_to_slack(stream_name, record = {})
            args = build_args(stream_name, record)
            response = @client.send(stream_name, **args)
            [args, response]
          end

          def build_args(stream_name, record)
            case stream_name
            when "chat_postMessage"
              { channel: channel_id, text: slack_code_block(record) }
            else
              raise "Stream name not found: #{stream_name}"
            end
          end

          def slack_code_block(data)
            longest_key = data.keys.map(&:to_s).max_by(&:length).length
            table_str = "```\n"
            data.each do |key, value|
              table_str += "#{key.to_s.ljust(longest_key)} : #{value}\n"
            end
            table_str += "```"

            table_str
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
