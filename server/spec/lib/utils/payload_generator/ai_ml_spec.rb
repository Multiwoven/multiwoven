# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::PayloadGenerator::AiMl do
  describe ".generate_payload" do
    context "when generating a nested payload from a complex flat hash" do
      it "creates a valid nested structure with dynamic and static values" do
        flat_hash = [
          { "name" => "messages.0.role", "type" => "string", "value" => "key1", "value_type" => "dynamic" },
          { "name" => "messages.0.content", "type" => "string", "value" => "key2", "value_type" => "dynamic" },
          { "name" => "messages.0.test", "type" => "string", "value" => "hai", "value_type" => "static" },
          { "name" => "messages.0.new.id", "type" => "number", "value" => "1", "value_type" => "static" },
          { "name" => "messages.1.role", "type" => "string", "value" => "key3", "value_type" => "dynamic" },
          { "name" => "messages.1.content", "type" => "string", "value" => "key4", "value_type" => "dynamic" },
          { "name" => "messages.1.test", "type" => "string", "value" => "hello", "value_type" => "static" },
          { "name" => "messages.1.details.info", "type" => "string", "value" => "key5", "value_type" => "dynamic" },
          { "name" => "meta.version", "type" => "number", "value" => "3", "value_type" => "static" },
          { "name" => "meta.status", "type" => "boolean", "value" => "true", "value_type" => "static" }
        ]

        harvest_values = {
          "key1" => "user",
          "key2" => "Hello there",
          "key3" => "assistant",
          "key4" => "How can I assist?",
          "key5" => "additional info"
        }

        expected_payload = {
          "messages" => [
            {
              "role" => "user",
              "content" => "Hello there",
              "test" => "hai",
              "new" => {
                "id" => 1
              }
            },
            {
              "role" => "assistant",
              "content" => "How can I assist?",
              "test" => "hello",
              "details" => {
                "info" => "additional info"
              }
            }
          ],
          "meta" => {
            "version" => 3,
            "status" => true
          }
        }

        result = described_class.generate_payload(flat_hash, harvest_values)
        expect(result).to eq(expected_payload)
      end
    end
  end

  context "when the input is empty" do
    it "returns an empty hash" do
      flat_hash = []
      harvest_values = {}

      expected_payload = {}

      result = described_class.generate_payload(flat_hash, harvest_values)
      expect(result).to eq(expected_payload)
    end
  end

  context "when harvest_values are missing for dynamic values" do
    it "handles missing dynamic values and returns the payload with nil values" do
      flat_hash = [
        { "name" => "messages.0.role", "type" => "string", "value" => "key1", "value_type" => "dynamic" },
        { "name" => "messages.0.content", "type" => "string", "value" => "key2", "value_type" => "dynamic" },
        { "name" => "messages.0.test", "type" => "string", "value" => "hai", "value_type" => "static" }
      ]

      harvest_values = {
        # Dynamic values for key1 and key2 are missing
      }

      expected_payload = {
        "messages" => [
          {
            "role" => "",
            "content" => "",
            "test" => "hai"
          }
        ]
      }

      result = described_class.generate_payload(flat_hash, harvest_values)
      expect(result).to eq(expected_payload)
    end
  end

  context "when invalid types are provided in flat_hash" do
    it "returns the payload and skips invalid types" do
      flat_hash = [
        { "name" => "messages.0.role", "type" => "invalid_type", "value" => "key1", "value_type" => "dynamic" },
        { "name" => "messages.0.content", "type" => "string", "value" => "key2", "value_type" => "dynamic" },
        { "name" => "messages.0.test", "type" => "string", "value" => "hai", "value_type" => "static" }
      ]

      harvest_values = {
        "key1" => "user",
        "key2" => "Hello there"
      }

      expected_payload = {
        "messages" => [
          {
            "role" => "user",
            "content" => "Hello there",
            "test" => "hai"
          }
        ]
      }

      result = described_class.generate_payload(flat_hash, harvest_values)
      expect(result).to eq(expected_payload)
    end
  end
end
