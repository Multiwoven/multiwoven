# frozen_string_literal: true

module ReverseEtl
  module Utils
    class RandomQueryBuilder
      def self.build_random_record_query(sync_config)
        existing_query = sync_config.model.query
        query_type = sync_config.source.query_type || "raw_sql"

        case query_type.to_sym
        when :soql
          existing_query
        when :raw_sql
          if sync_config.source.name == "Bigquery"
            "SELECT * FROM (#{existing_query}) AS subquery ORDER BY RAND()"
          else
            "SELECT * FROM (#{existing_query}) AS subquery ORDER BY RANDOM()"
          end
        end
      end
    end
  end
end
