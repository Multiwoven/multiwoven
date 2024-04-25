# frozen_string_literal: true

require "aws-sdk-s3"

module Multiwoven::Integrations::Source
  module S3
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        # WIP
        s3 = create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
        # TODO: implement
      rescue StandardError => e
        handle_exception(
          "S3:DISCOVER:EXCEPTION",
          "error",
          e
        )
      end

      def read(sync_config)
        # TODO: implement
      rescue StandardError => e
        handle_exception(
          "S3:READ:EXCEPTION",
          "error",
          e
        )
      end

      private

      def query(connection, query)
        # TODO: implement
      end

      def create_connection(connection_config)
        # TODO: implement
      end

      def create_streams(records)
        # TODO: implement
      end

      def group_by_table(records)
        # TODO: implement
      end
    end
  end
end
