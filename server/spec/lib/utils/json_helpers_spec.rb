# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::JsonHelpers do
  include Utils::JsonHelpers

  describe "#resolve_values_from_env" do
    before do
      ENV["TEST_KEY"] = "resolved_value"
      ENV["ANOTHER_KEY"] = "another_value"
      ENV["TEST_USER"] = "test_user_value"
      ENV["TEST_PASSWORD"] = "test_password_value"
    end

    after do
      ENV.delete("TEST_KEY")
      ENV.delete("ANOTHER_KEY")
      ENV.delete("TEST_USER")
      ENV.delete("TEST_PASSWORD")
    end

    it "resolves environment variable values from JSON hash" do
      json_hash = {
        "key1" => "ENV['TEST_KEY']",
        "key2" => "static_value"
      }

      result = resolve_values_from_env(json_hash)

      expect(result["key1"]).to eq("resolved_value")
      expect(result["key2"]).to eq("static_value")
    end

    it "returns original values if not environment variables" do
      json_hash = {
        "key1" => "some_value",
        "key2" => "another_value"
      }

      result = resolve_values_from_env(json_hash)

      expect(result).to eq(json_hash)
    end

    it "resolves multiple environment variables with nested structure" do
      json_hash = {
        "key1" => "ENV['TEST_KEY']",
        "key2" => 'ENV["ANOTHER_KEY"]',
        "connection_spec": {
          "credentials": {
            "auth_type": "test",
            "password": "ENV['TEST_PASSWORD']",
            "username": "ENV[\"TEST_USER\"]"
          },
          "host": "test",
          "port": "6543",
          "schema": "public",
          "database": "postgres"
        }
      }

      result = resolve_values_from_env(json_hash)
      result = JSON.parse(result.to_json)
      expect(result["key1"]).to eq("resolved_value")
      expect(result["key2"]).to eq("another_value")
      expect(result["connection_spec"]["credentials"]["password"]).to eq("test_password_value")
      expect(result["connection_spec"]["credentials"]["username"]).to eq("test_user_value")
    end

    it "returns nil for undefined environment variables" do
      json_hash = {
        "key1" => "ENV['UNDEFINED_KEY']"
      }

      result = resolve_values_from_env(json_hash)

      expect(result["key1"]).to be_nil
    end
  end
end
