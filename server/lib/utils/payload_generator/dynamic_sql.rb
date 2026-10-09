# frozen_string_literal: true

module Utils
  module PayloadGenerator
    module DynamicSql
      def self.generate_query(model, harvest_values)
        dynamic_query = model.query
        input_config = model.json_schema["input"]

        input_config.each do |config|
          dynamic_var_name = ":#{config['name']}"
          raw_value = config["value_type"] == "static" ? config["value"] : harvest_values[config["name"]]
          dynamic_var_value = if config["type"] == "string"
                                if already_quoted?(dynamic_query, dynamic_var_name)
                                  raw_value.gsub("'", "''")
                                else
                                  "'#{raw_value.gsub("'", "''")}'"
                                end
                              else
                                raw_value.to_s
                              end

          dynamic_query.gsub!(dynamic_var_name, dynamic_var_value)
        end

        dynamic_query
      end

      def self.already_quoted?(query, placeholder)
        query.match?(/'\s*#{Regexp.escape(placeholder)}\s*'/)
      end
    end
  end
end
