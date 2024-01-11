# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class SourceConnector < BaseConnector
      def read(_sync_config)
        raise "Not implemented"
        # return list of RecordMessage
      end

      private

      def batched_query(sql_query, offset, limit)
        offset = offset.to_i
        limit = limit.to_i
        raise ArgumentError, "Offset and limit must be non-negative" if offset.negative? || limit.negative?

        # Removing any trailing semicolons
        sql_query.chomp!(";")

        # Checking if the query already has a LIMIT clause
        raise ArgumentError, "Query already contains a LIMIT clause" if sql_query.match?(/LIMIT \d+/i)

        # Appending the LIMIT and OFFSET clauses to the SQL query
        "#{sql_query} LIMIT #{limit} OFFSET #{offset}"
      end
    end
  end
end
