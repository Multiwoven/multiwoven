# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module AmazonS3
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        config_aws(connection_config)
        initialize_client(connection_config)
        resp = read_file(connection_config)
        file_contents = resp.body.read
        csv_data = CSV.parse(file_contents, headers: true)
        puts resp
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover(connection_config)
      rescue StandardError => e
        handle_exception("AMAZONS3:DISCOVER:EXCEPTION", "error", e)
      ensure
        db&.close
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        config_aws(connection_config)
        initialize_client(connection_config)
        resp = read_file(connection_config)
        file_contents = resp.body.read
        csv_data = CSV.parse(file_contents, headers: true)
      rescue StandardError => e
        handle_exception("AMAZONS3:READ:EXCEPTION", "error", e)
      end

      private

      def config_aws(config)
        config = config.with_indifferent_access
        Aws.config.update({
          region: config[:region],
          credentials: Aws::Credentials.new(config[:access_id], config[:secret_access])
        })
      end

      def initialize_client(config)
        config = config.with_indifferent_access
        @client = Aws::S3::Client.new
      end

      def read_file(config)
        config = config.with_indifferent_access
        bucket_name = config[:bucket]
        file_key = config[:file_key]
        @client.get_object(bucket: bucket_name, key: file_key)
      end
    end
  end
end
