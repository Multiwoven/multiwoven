# frozen_string_literal: true

require "sentry-ruby"

module Multiwoven::Integrations::Destination
  module Sentry
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      attr_reader :dsn_link

      def initialize(connection_config)
        @dsn_link = connection_config[:dsn]
        configure_sentry(connection_config)
      end

      def check_connection
        response = Multiwoven::Integrations::Core::HttpClient.request(
          host,
          "POST",
          headers: {
            "Content-Type" => "application/json",
            "X-Sentry-Auth" => "Sentry sentry_version=7, sentry_key=#{public_key}"
          }
        )
        if response[:code].to_i == 200
          success_status
        else
          failure_status
        end
      rescue StandardError => e
        handle_exception(e,
                         context: "SENTRY::CONNECTION::FAILURE",
                         type: "error")
        failure_status
      end

      def write(sync_config, records)
        @sync_config = sync_config
        process_records(records)
      rescue StandardError => e
        handle_exception(e, {
                           context: "SENTRY:WRITE:EXCEPTION",
                           type: "error",
                           sync_id: @sync_config.sync_id,
                           sync_run_id: @sync_config.sync_run_id
                         })
      end

      private

      def process_records(sync_config, records)
        write_success = 0
        write_failure = 0
        records.each do |record|
          ::Sentry.capture_exception(record)
          write_success += 1
        rescue StandardError => e
          write_failure += 1
          handle_exception(e, {
                             context: "SENTRY:WRITE:EXCEPTION",
                             type: "error",
                             sync_id: sync_config.sync_id,
                             sync_run_id: sync_config.sync_run_id
                           })
        end
      end

      def configure_sentry(connection_config)
        ::Sentry.init do |config|
          config.dsn = connection_config[:dsn]
          config.environment = connection_config[:environment]
          config.release = connection_config[:release] || "default-release"
          config.debug = connection_config[:debug] || true
          config.traces_sample_rate = connection_config[:traces_sample_rate] || 0.5
          config.breadcrumbs_logger = %i[active_support_logger http_logger]
          config.background_worker_threads = connection_config[:worker_threads] || 5

          config.excluded_exceptions = connection_config[:excluded_exceptions] || []
          config.before_send = lambda do |event, hint|
            if hint[:exception] && config.excluded_exceptions.any? { |e| hint[:exception].is_a?(e) }
              nil
            else
              event
            end
          end
        end
      end

      def dsn
        @dsn ||= ::Sentry::DSN.new(@dsn_link)
      end

      def host
        @host ||= dsn.host
      end

      def public_key
        @public_key ||= dsn.public_key
      end

      def success_status
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      end

      def failure_status(_exception = nil)
        ConnectionStatus.new(status: ConnectionStatusType["failed"]).to_multiwoven_message
      end
    end
  end
end
