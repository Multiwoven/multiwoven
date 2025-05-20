# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"
require "rack"
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

use Rack::Deflater
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

run Rails.application
Rails.application.load_server
