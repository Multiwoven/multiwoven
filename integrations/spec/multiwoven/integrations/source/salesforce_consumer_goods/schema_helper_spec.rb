# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::SalesforceConsumerGoodsCloud::SchemaHelper do
  describe ".salesforce_field_to_json_schema_type" do
    context "when the field type is string and nillable" do
      let(:sf_field) { { "type" => "string", "nillable" => true } }

      it "returns a schema allowing null values" do
        expect(described_class.salesforce_field_to_json_schema_type(sf_field)).to eq({ type: %w[string null] })
      end
    end

    context "when the field type is location and not nillable" do
      let(:sf_field) { { "type" => "location", "nillable" => false } }

      it "returns a correct object schema for geolocation" do
        expected_schema = {
          type: "object",
          properties: {
            latitude: { type: "number" },
            longitude: { type: "number" }
          }
        }
        expect(described_class.salesforce_field_to_json_schema_type(sf_field)).to eq(expected_schema)
      end
    end
  end

  describe ".create_json_schema_for_object" do
    let(:metadata) do
      {
        "name" => "TestObject",
        "fields" => [
          { "name" => "Field1", "type" => "string", "nillable" => false },
          { "name" => "Field2", "type" => "int", "nillable" => true }
        ]
      }
    end

    it "creates a valid JSON schema for a Salesforce object" do
      result = described_class.create_json_schema_for_object(metadata)

      expect(result[:name]).to eq("TestObject")
      expect(result[:action]).to eq("create")
      expect(result[:json_schema]).to be_a(Hash)
      expect(result[:required]).to contain_exactly("Field1")
      expect(result[:supported_sync_modes]).to contain_exactly("incremental")
      expect(result[:source_defined_cursor]).to eq(false)
      expect(result[:default_cursor_field]).to eq(nil)
    end
  end
end
