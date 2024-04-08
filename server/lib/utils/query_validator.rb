# frozen_string_literal: true

module Utils
  module QueryValidator
    def self.validate_query(query_type, query)
      case query_type.to_sym
      when :raw_sql
        begin
          PgQuery.parse(query)
        rescue PgQuery::ParseError => e
          raise StandardError, "Query contains invalid SQL syntax: #{e.message}"
        end
      when :soql
        begin
          # TODO SOQL
        rescue StandardError => e
          raise StandardError, "Query contains invalid SOQL syntax: #{e.message}"
        end
      else
        raise StandardError, "Unsupported query_type"
      end
    end
  end
end
