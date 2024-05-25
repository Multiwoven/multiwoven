# frozen_string_literal: true

if ENV["APPSIGNAL_PUSH_API_KEY"]
  appsignal_logger = Appsignal::Logger.new("rails")
  Rails.logger.broadcast_to(appsignal_logger)
end