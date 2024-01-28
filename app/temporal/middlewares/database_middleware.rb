# frozen_string_literal: true

module Middlewares
  class DatabaseMiddleware
    def call(_metadata)
      ActiveRecord::Base.connection_pool.with_connection do
        yield
      ensure
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.connection.close
      end
    end
  end
end
