require 'temporal'
require 'temporal/metrics_adapters/log'

metrics_logger = Logger.new(STDOUT, progname: 'metrics')

Temporal.configure do |config|
  config.host = ENV.fetch('TEMPORAL_HOST', 'localhost')
  config.port = ENV.fetch('TEMPORAL_PORT', 7233).to_i
  config.namespace = ENV.fetch('TEMPORAL_NAMESPACE', 'multiwoven-dev')
  config.task_queue = ENV.fetch('TEMPORAL_TASK_QUEUE', 'sync-dev')
  config.metrics_adapter = Temporal::MetricsAdapters::Log.new(metrics_logger)
end


Multiwoven::Integrations::Service.new do |config|
  config.logger = Temporal.logger
end