# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Slack
        include Multiwoven::Integrations::Core

        class Client < DestinationConnector
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
            catalog = build_catalog(load_catalog_streams)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception("SLACK:DISCOVER:EXCEPTION", "error", e)
          end

          def write(sync_config, records, action = "create")
            # Currently as we only create a message for each record in slack, we are not using actions.
            # This will be changed in future.

            @action = sync_config.stream.action || action
            connection_config = sync_config.destination.connection_specification.with_indifferent_access
            configure_slack(connection_config[:api_token])
            @client = ::Slack::Web::Client.new
            @channel_id = connection_config[:channel_id]
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception("SLACK:WRITE:EXCEPTION", "error", e)
          end

          private

          def configure_slack(api_token)
            ::Slack.configure do |config|
              config.token = api_token
            end
          end

          def process_records(records, stream)
            write_success = 0
            write_failure = 0
            records.each do |record_object|
              process_record(stream, record_object.with_indifferent_access)
              write_success += 1
            rescue StandardError => e
              write_failure += 1
              handle_exception("SLACK:CRM:WRITE:EXCEPTION", "error", e)
            end
            tracking_message(write_success, write_failure)
          end

          def process_record(stream, record)
            send_data_to_slack(stream[:name], record)
          end

          def send_data_to_slack(stream_name, record = {})
            args = build_args(stream_name, record)
            @client.send(stream_name, **args)
          end

          def build_args(stream_name, record)
            case stream_name
            when "chat_postMessage"
              { channel: channel_id, text: slack_code_block(record[:data][:attributes]) }
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

          def load_catalog_streams
            catalog_json = read_json(CATALOG_SPEC_PATH)
            catalog_json["streams"].map { |stream| build_stream(stream) }
          end

          def build_stream(stream)
            Multiwoven::Integrations::Protocol::Stream.new(
              name: stream["name"], json_schema: stream["json_schema"],
              action: stream["action"]
            )
          end

          def build_catalog(streams)
            Multiwoven::Integrations::Protocol::Catalog.new(streams: streams)
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
