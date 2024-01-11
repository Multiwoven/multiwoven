# frozen_string_literal: true

# app/middleware/multiwoven_server/quiet_logger.rb
module MultiwovenServer
  class QuietLogger < Rails::Rack::Logger
    def call(env)
      previous_level = Rails.logger.level
      Rails.logger.level = Logger::ERROR if env["PATH_INFO"] == "/"
      super(env)
    ensure
      Rails.logger.level = previous_level
    end
  end
end
