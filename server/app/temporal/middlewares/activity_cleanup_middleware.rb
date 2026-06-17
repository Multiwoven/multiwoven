# frozen_string_literal: true

module Middlewares
  class ActivityCleanupMiddleware
    def call(_metadata)
      yield
    ensure
      ActiveRecord::Base.connection_handler.clear_active_connections!
    end
  end
end
