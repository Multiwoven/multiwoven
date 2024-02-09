# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class SourceConnector < BaseConnector
      # accepts Protocol::SyncConfig
      def read(_sync_config)
        raise "Not implemented"
        # setup sync configs
        # call query(connection, query)
        # Returns list of RecordMessage
      end

      private

      # This needs to be implemented as private method
      # In every source connector. This will be used for model preview
      def query(connection, query)
        # return list of RecordMessage
      end

      def batched_query(sql_query, limit, offset)
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
