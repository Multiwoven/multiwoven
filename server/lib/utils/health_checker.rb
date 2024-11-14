module Utils
  class HealthChecker
    def self.run
      health_check_port = ENV["MULTIWOVEN_WORKER_HEALTH_CHECK_PORT"] || 4567

      server = WEBrick::HTTPServer.new(Port: health_check_port)
      server.mount_proc "/health" do |_req, res|
        res.body = "Service is healthy"
      end

      trap "INT" do
        server.shutdown
      end

      Thread.new do
        server.start
      end
    end
  end
end
