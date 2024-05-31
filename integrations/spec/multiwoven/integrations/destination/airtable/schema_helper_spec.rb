# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Airtable::SchemaHelper do
  let(:sample_table) do
    {
      "id": "tblNewID",
      "name": "New Table Name",
      "primaryFieldId": "new_primary_field_id",
      "fields": [
        {
          "type": "singleLineText",
          "id": "new_id_1",
          "name": "New Name 1"
        },
        {
          "type": "formula",
          "options": {
            "isValid": true,
            "formula": "1+1",
            "referencedFieldIds": [],
            "result": {
              "type": "number",
              "options": {
                "precision": 0
              }
            }
          },
          "id": "new_id_2",
          "name": "New Formula 1"
        },
        {
          "type": "formula",
          "options": {
            "isValid": true,
            "formula": "ARRAYFLATTEN(1,2,3)",
            "referencedFieldIds": [],
            "result": {
              "type": "string",
              "options": {
                "precision": 0
              }
            }
          },
          "id": "new_id_3",
          "name": "New Formula 2"
        },
        {
          "type": "singleSelect",
          "options": {
            "choices": [
              {
                "id": "new_choice_id_1",
                "name": "New Todo",
                "color": "redLight2"
              },
              {
                "id": "new_choice_id_2",
                "name": "New In progress",
                "color": "yellowLight2"
              },
              {
                "id": "new_choice_id_3",
                "name": "New Done",
                "color": "greenLight2"
              }
            ]
          },
          "id": "new_id_4",
          "name": "New Status"
        },
        {
          "type": "number",
          "options": {
            "precision": 1
          },
          "id": "new_id_5",
          "name": "New Float"
        },
        {
          "type": "barcode",
          "id": "new_id_6",
          "name": "New Barcode"
        },
        {
          "type": "multipleRecordLinks",
          "options": {
            "linkedTableId": "tblNewID",
            "isReversed": false,
            "prefersSingleRecordLink": false
          },
          "id": "new_id_7",
          "name": "New Link to Table"
        },
        {
          "type": "multipleLookupValues",
          "options": {
            "isValid": true,
            "recordLinkFieldId": "new_id_7",
            "fieldIdInLinkedTable": "new_id_2",
            "result": {
              "type": "number",
              "options": {
                "precision": 0
              }
            }
          },
          "id": "new_id_8",
          "name": "New Lookup Value"
        }
      ],
      "views": [
        {
          "id": "new_view_id",
          "name": "New Grid View",
          "type": "grid"
        }
      ]
    }.with_indifferent_access
  end

  let(:expected_schema) do
    {
      "$schema": "https://json-schema.org/draft-07/schema#",
      "additionalProperties": true,
      "type": "object",
      "properties": {
        "New_Name_1": { # rubocop:disable Naming/VariableNumber
          "type": %w[null string]
        },
        "New_Formula_1": { # rubocop:disable Naming/VariableNumber
          "type": %w[null number]
        },
        "New_Formula_2": { # rubocop:disable Naming/VariableNumber
          "items": {
            "type": %w[null string]
          },
          "type": %w[null array]
        },
        "New_Status": {
          "type": %w[null string]
        },
        "New_Float": {
          "type": %w[null number]
        },
        "New_Barcode": {
          "type": %w[null string]
        },
        "New_Link_to_Table": {
          "items": {
            "type": %w[null string]
          },
          "type": %w[null array]
        },
        "New_Lookup_Value": {
          "items": {
            "type": %w[null number]
          },
          "type": %w[null array]
        }
      }
    }.with_indifferent_access
  end

  describe ".clean_name" do
    it "replaces spaces with underscores and strips whitespace" do
      expect(described_class.clean_name(" Table 1 ")).to eq("Table_1")
    end
  end

  describe ".get_json_schema" do
    it "returns a json schema with properties based on the table fields" do
      schema = described_class.get_json_schema(sample_table)
      expect(schema).to eq(expected_schema)
    end
  end
end
