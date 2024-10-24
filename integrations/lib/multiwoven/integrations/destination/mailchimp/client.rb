# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Mailchimp
        include Multiwoven::Integrations::Core

        API_VERSION = "3.0"

        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::RateLimiter

          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            initialize_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog = build_catalog(load_catalog)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "MAILCHIMP:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, action = "create")
            @sync_config = sync_config
            @action = sync_config.stream.action || action
            initialize_client(sync_config.destination.connection_specification)
            process_records(records, sync_config.stream)
          rescue StandardError => e
            handle_exception(e, {
                               context: "MAILCHIMP:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: @sync_config.sync_id,
                               sync_run_id: @sync_config.sync_run_id
                             })
          end

          private

          def initialize_client(config)
            config = config.with_indifferent_access
            @client = MailchimpMarketing::Client.new
            @client.set_config({
                                 api_key: config[:api_key],
                                 server: config[:api_key].split("-").last
                               })
            @list_id = config[:list_id]
          end

          def process_records(records, stream)
            log_message_array = []
            write_success = 0
            write_failure = 0
            properties = stream.json_schema[:properties]

            records.each do |record_object|
              record = extract_data(record_object, properties)
              args = [stream.name, "Id", record]
              begin
                response = send_to_mailchimp(record, stream.name)
                write_success += 1
                log_message_array << log_request_response("info", args, response)
              rescue StandardError => e
                handle_exception(e, {
                                   context: "MAILCHIMP:WRITE:EXCEPTION",
                                   type: "error",
                                   sync_id: @sync_config.sync_id,
                                   sync_run_id: @sync_config.sync_run_id
                                 })
                write_failure += 1
                log_message_array << log_request_response("error", args, e.message)
              end
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          def send_to_mailchimp(record, stream_name)
            case stream_name
            when "Audience"
              @client.lists.set_list_member(@list_id, Digest::MD5.hexdigest(record[:email].downcase), {
                                              email_address: record[:email],
                                              status_if_new: "subscribed",
                                              merge_fields: {
                                                FNAME: record[:first_name],
                                                LNAME: record[:last_name]
                                              }
                                            })
            when "Tags"
              @client.lists.update_list_member_tags(@list_id, Digest::MD5.hexdigest(record[:email].downcase), {
                                                      tags: record[:tags].map { |tag| { name: tag, status: "active" } }
                                                    })
            when "Campaigns"
              campaign = @client.campaigns.create({
                                                    type: "regular",
                                                    recipients: { list_id: @list_id },
                                                    settings: {
                                                      subject_line: record[:subject],
                                                      from_name: record[:from_name],
                                                      reply_to: record[:reply_to]
                                                    }
                                                  })
              if record[:email_template_id]
                @client.campaigns.set_content(campaign["id"], {
                                                template: { id: record[:email_template_id] }
                                              })
              else
                @client.campaigns.set_content(campaign["id"], {
                                                plain_text: record[:content]
                                              })
              end
              @client.campaigns.send(campaign["id"])
            else
              raise "Unsupported stream type: #{stream_name}"
            end
          end

          def authenticate_client
            @client.lists.get_all_lists
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def log_debug(message)
            Multiwoven::Integrations::Service.logger.debug(message)
          end
        end
      end
    end
  end
end
