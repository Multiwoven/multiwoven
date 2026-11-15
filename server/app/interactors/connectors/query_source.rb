# frozen_string_literal: true

module Connectors
  class QuerySource
    include Interactor

    UNSUPPORTED_QUERY_ERROR = "This connector does not support querying"

    def call
      result = context.connector.execute_query(context.query, limit: context.limit)
    rescue NotImplementedError
      context.fail!(error: UNSUPPORTED_QUERY_ERROR)
    rescue StandardError => e
      Utils::ExceptionReporter.report(e)
      context.fail!(error: e.message)
    else
      context.fail!(error: result.log.message) if log_message?(result)
      # Sources without a query implementation return nil instead of records.
      context.fail!(error: UNSUPPORTED_QUERY_ERROR) unless result.is_a?(Array)
      context.records = result
    end

    private

    def log_message?(result)
      result.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage) && result.log.present?
    end
  end
end
