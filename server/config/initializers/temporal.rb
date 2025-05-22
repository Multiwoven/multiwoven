# frozen_string_literal: true

require Rails.root.join("lib/utils/exception_reporter")

Multiwoven::Integrations::Service.new do |config|
  config.logger = Rails.logger
  config.exception_reporter = Utils::ExceptionReporter
end

# Override Temporal.warn to silence deprecation warnings
def Temporal.warn(msg)
  # Only log if it's not the deprecation warning
  Rails.logger.warn(msg) unless msg.include?('deprecated without a substitution')
end

module TemporalService
  def self.setup
    require "temporal"
    require "temporal/metrics_adapters/log"
    metrics_logger = Logger.new($stdout, progname: "metrics")
    client_key_path = ENV.fetch("TEMPORAL_ROOT_CERT", "app/temporal/cli/client.key")
    client_cert_path = ENV.fetch("TEMPORAL_CLIENT_KEY", "app/temporal/cli/client.pem")

    if File.exist?(client_key_path) && File.exist?(client_cert_path)
      client_key = File.read(client_key_path)
      client_cert = File.read(client_cert_path)
    end

    Temporal.configure do |config|
      config.host = ENV.fetch("TEMPORAL_HOST", "localhost")
      config.port = ENV.fetch("TEMPORAL_PORT", 7233).to_i
      config.namespace = ENV.fetch("TEMPORAL_NAMESPACE", "multiwoven-dev")
      config.task_queue = ENV.fetch("TEMPORAL_TASK_QUEUE", "sync-dev")
      config.metrics_adapter = Temporal::MetricsAdapters::Log.new(metrics_logger)
      if client_key && client_cert
        config.credentials = GRPC::Core::ChannelCredentials.new(
          nil,
          client_key,
          client_cert
        )
      end
    end
  end
end
