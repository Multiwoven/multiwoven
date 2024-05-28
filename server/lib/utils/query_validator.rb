# frozen_string_literal: true

module Utils
  module QueryValidator
    def self.validate_query(connector, _query)
      case connector.connector_query_type.to_sym
      when :raw_sql

        begin
          # Bigquery doesn't support PG query parser, so this throws an error.
          # So commenting this out and we need to figure out a better way to do this.
          # TODO: Find a way to validate Bigquery queries and enable validation for PG related queries.
          # PgQuery.parse(query)
        rescue PgQuery::ParseError => e
          raise StandardError, "Query contains invalid SQL syntax: #{e.message}"
        end
      when :soql
        begin
          # TODO: SOQL
        rescue StandardError => e
          raise StandardError, "Query contains invalid SOQL syntax: #{e.message}"
        end
      else
        raise StandardError, "Unsupported query_type"
      end
    end
  end
end
