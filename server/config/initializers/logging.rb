# frozen_string_literal: true

if ENV["APPSIGNAL_PUSH_API_KEY"]
  appsignal_logger = Appsignal::Logger.new("rails")
  tagged_appsignal_logger = ActiveSupport::TaggedLogging.new(appsignal_logger)
  Rails.logger.broadcast_to(tagged_appsignal_logger)
end
