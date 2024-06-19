# frozen_string_literal: true

unless Rails.env.test?
  # ALLOWED_HOST used for our self hosted EE deployments
  if ENV["ALLOWED_HOST"]
    Rails.application.config.hosts << ENV["ALLOWED_HOST"]
  else
    # Enterprise SAAS deployments
    Rails.application.config.hosts << ".squared.ai"
    Rails.application.config.hosts << ".staging.squared.ai"
    # Local development
    Rails.application.config.hosts << "localhost"
  end
  Rails.application.config.host_authorization = {
    # Exclude health check from  host header auth.
    # Health check endpoint is at "/" path
    exclude: ->(request) { request.path == "/" }
  }
end
