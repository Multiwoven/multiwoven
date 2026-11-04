# frozen_string_literal: true

module Connectors
  class QuerySource
    include Interactor

<<<<<<< HEAD
    def call
      result = context.connector.execute_query(context.query, limit: context.limit)
      context.records = result
=======
    UNSUPPORTED_QUERY_ERROR = "This connector does not support querying"
    USER_QUERY_ERRORS = [
      PG::UndefinedColumn,
      PG::UndefinedTable,
      PG::UndefinedFunction,
      PG::InvalidTextRepresentation
    ].freeze

    def call
      result = context.connector.execute_query(context.query, limit: context.limit)
    rescue NotImplementedError
      context.fail!(error: UNSUPPORTED_QUERY_ERROR)
    rescue *USER_QUERY_ERRORS => e
      Rails.logger.info("Connectors::QuerySource query rejected by source: #{e.class}")
      context.fail!(error: e.message)
>>>>>>> d4d3a541e (fix(CE): Stop reporting expected Postgres query errors from QuerySource to AppSignal (BE-2051) (#2361))
    rescue StandardError => e
      Utils::ExceptionReporter.report(e)
      context.fail!(error: e.message)
    end
  end
end
