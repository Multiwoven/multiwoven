# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"
require "rack"
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

<<<<<<< HEAD
use Rack::Deflater
use Prometheus::Middleware::Collector
=======
# Rack::Deflater compresses responses with gzip. SSE streams must be excluded
# because the deflater buffers the full body before sending.
use Rack::Deflater, if: lambda { |_env, _status, headers, _body|
  content_type = headers["Content-Type"] || headers["content-type"]
  !content_type&.include?("text/event-stream")
}
require_relative "app/middleware/multiwoven_server/csrf_guard"
use MultiwovenServer::CsrfGuard

require_relative "app/middleware/multiwoven_server/metrics_auth"
use MultiwovenServer::MetricsAuth

require_relative "app/middleware/conditional_prometheus_collector"
use ConditionalPrometheusCollector
>>>>>>> 20c70131b (chore(CE): added backwards compatible logic to handle the csrf and h… (#2034))
use Prometheus::Middleware::Exporter

run Rails.application
Rails.application.load_server
