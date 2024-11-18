# frozen_string_literal: true

module Utils
  module PayloadGenerator
    module DynamicSql
      def self.generate_query(model, harvest_values)
        dynamic_query = model.query
        input_config = model.json_schema["input"]

        input_config.each do |config|
          dynamic_var_name = ":#{config['name']}"
          dynamic_var_value = config["value_type"] == "static" ? config["value"] : harvest_values[config["name"]]

          dynamic_query.gsub!(dynamic_var_name, dynamic_var_value)
        end

        dynamic_query
      end
    end
  end
end
