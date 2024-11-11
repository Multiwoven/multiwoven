# frozen_string_literal: true

require "puma"
require "rack"

module Utils
  class HealthChecker
    HEALTH_CHECK_HOST = ENV["MULTIWOVEN_WORKER_HEALTH_CHECK_HOST"] || "127.0.0.1"
    HEALTH_CHECK_PORT = ENV["MULTIWOVEN_WORKER_HEALTH_CHECK_PORT"] || 4567

    @server = nil

    def self.run
      app = proc do |env|
        if env["PATH_INFO"] == "/health"
          [200, { "Content-Type" => "text/plain" }, ["Service is healthy"]]
        else
          [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
        end
      end

      @server = Puma::Server.new(app)
      @server.add_tcp_listener(HEALTH_CHECK_HOST, HEALTH_CHECK_PORT.to_i)

      # Start the server in a new thread
      Thread.new do
        puts "Starting Puma health check server on #{HEALTH_CHECK_HOST}:#{HEALTH_CHECK_PORT}"
        @server.run
      end

      # Handle signals for graceful shutdown
      %w[INT TERM].each do |signal|
        trap(signal) do
          puts "Received #{signal}, shutting down Puma health check server..."
          shutdown
        end
      end
    end

    def self.shutdown
      return unless @server

      @server.stop(true) # Graceful shutdown
      puts "Puma health check server stopped."
    end
  end
end
