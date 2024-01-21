# frozen_string_literal: true

module Models
  class ExecuteQuery
    include Interactor

    def call
      records = context.connector.execute_query(context.query, limit: context.limit)
      context.records = records
    rescue StandardError => e
      context.fail!(errors: e.message)
    end
  end
end
