# frozen_string_literal: true

module Connectors
  class ExecuteModel
    include Interactor

    def call
      result = context.connector.generate_response(context.payload)
      context.records = result
    rescue StandardError => e
      Utils::ExceptionReporter.report(e)
      context.fail!(error: e.message)
    end
  end
end
