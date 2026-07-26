# frozen_string_literal: true

module Middlewares
  class DatabaseMiddleware
    def call(_metadata)
      ActiveRecord::Base.connection_handler
                        .retrieve_connection_pool("ActiveRecord::Base")
                        .with_connection do
        yield
      ensure
        ActiveRecord::Base.connection_handler.clear_active_connections!
      end
    end
  end
end
