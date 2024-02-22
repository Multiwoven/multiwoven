# frozen_string_literal: true

module Connectors
  class QuerySource
    include Interactor

    def call
      result = context.connector.execute_query(context.query, limit: context.limit)
      context.records = result
    rescue StandardError => e
      context.fail!(error: e.message)
    end
  end
end
