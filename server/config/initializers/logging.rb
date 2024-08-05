# frozen_string_literal: true

if ENV["APPSIGNAL_PUSH_API_KEY"]
  appsignal_logger = Appsignal::Logger.new("rails")
  Rails.logger.broadcast_to(appsignal_logger)
end

Rails.logger.info "GRPC_ENABLE_FORK_SUPPORT: #{ENV['GRPC_ENABLE_FORK_SUPPORT']}"
Rails.logger.info "ALLOWED_HOSTS: #{ENV['ALLOWED_HOST']}"