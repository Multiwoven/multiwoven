# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class QueryBuilder
      def self.perform(action, table, record, primary_key = nil)
        case action.downcase
        when "insert"
          columns = record.keys.join(", ")
          values = record.values.map { |value| "'#{value}'" }.join(", ")
          # TODO: support bulk insert
          "INSERT INTO #{table} (#{columns}) VALUES (#{values});"
        when "update"
          # Ensure primary key is a string and exists within record for the WHERE clause
          return "Primary key '#{primary_key}' not found in record." if record[primary_key].nil?

          primary_key_value = record.delete(primary_key) # Remove and return the primary key value
          set_clause = record.map { |key, value| "#{key} = '#{value}'" }.join(", ")
          where_clause = "#{primary_key} = '#{primary_key_value}'"
          "UPDATE #{table} SET #{set_clause} WHERE #{where_clause};"
        else
          "Invalid action specified."
        end
      end
    end
  end
end
