# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::PayloadGenerator::DynamicSql do
  describe ".generate_query" do
    let!(:dynamic_sql_connector) do
      create(:connector, connector_name: "Postgres", connector_type: "source", connector_category: "Dynamic SQL")
    end

    let!(:dynamic_sql_model) do
      create(:model, query_type: :dynamic_sql, connector: dynamic_sql_connector,
                     configuration: {
                       json_schema: {
                         input: [{ "name" => "name",
                                   "type" => "string", "value" => "", "value_type" => "dynamic" },
                                 { "name" => "age",
                                   "type" => "number", "value" => "22", "value_type" => "static" },
                                 { "name" => "gender",
                                   "type" => "string", "value" => "", "value_type" => "dynamic" }],
                         output: []
                       },
                       harvesters: []
                     },
                     query: "SELECT * FROM public.actor WHERE name=':name' AND age=:age AND gender=':gender'")
    end

    let(:harvesters) do
      { "name" => "first_name", "gender" => "female" }
    end

    context "when correct input and harvest values are provided" do
      it "replaces dynamic query values and return raw query" do
        expected_query = "SELECT * FROM public.actor WHERE name='first_name' AND age=22 AND gender='female'"
        generated_query = described_class.generate_query(dynamic_sql_model, harvesters)
        expect(generated_query).to eq(expected_query)
      end
    end
  end
end
