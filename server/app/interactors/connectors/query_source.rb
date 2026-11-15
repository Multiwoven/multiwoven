# frozen_string_literal: true

module Connectors
  class QuerySource
    include Interactor

<<<<<<< HEAD
=======
    UNSUPPORTED_QUERY_ERROR = "This connector does not support querying"
    USER_QUERY_ERRORS = [
      PG::UndefinedColumn,
      PG::UndefinedTable,
      PG::UndefinedFunction,
      PG::InvalidTextRepresentation,
      PG::SyntaxError,
      Multiwoven::Integrations::Core::OauthClientCredentials::OauthTokenRequestError
    ].freeze

>>>>>>> 9a6a6e73e (fix(CE): Stop reporting PG::SyntaxError and OAuth token 4xx from QuerySource (BE-2068) (#2382))
    def call
      result = context.connector.execute_query(context.query, limit: context.limit)
      context.records = result
    rescue StandardError => e
      Utils::ExceptionReporter.report(e)
      context.fail!(error: e.message)
    end
  end
end
