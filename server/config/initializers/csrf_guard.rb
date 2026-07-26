# frozen_string_literal: true

# Mount MultiwovenServer::CsrfGuard AFTER Rack::Cors so a CSRF-mismatch 403
# response still gets Access-Control-Allow-Origin headers on the way out.
# Rack::Cors is inserted by config/initializers/cors.rb, which runs
# alphabetically before this file — so Rack::Cors is already in the stack.

require_relative "../../app/middleware/multiwoven_server/csrf_guard"

Rails.application.config.middleware.insert_after Rack::Cors, MultiwovenServer::CsrfGuard