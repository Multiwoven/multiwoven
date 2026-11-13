# frozen_string_literal: true

module ReverseEtl
  module Utils
    class RandomQueryBuilder
      def self.build_random_record_query(sync_config)
        existing_query = sync_config.model.query
        query_type = sync_config.source.query_type || "raw_sql"

        return existing_query if query_type.to_sym == :soql

        case sync_config.source.name
        when "Bigquery"
          "SELECT * FROM (#{existing_query}) AS subquery ORDER BY RAND()"
        when "SqlServer"
          "SELECT * FROM (#{existing_query.strip.chomp(';')}) AS subquery ORDER BY NEWID()"
        when "IntuitQuickBooks", "Odoo"
          existing_query
        else
          "SELECT * FROM (#{existing_query}) AS subquery ORDER BY RANDOM()"
        end
      end
    end
  end
end
