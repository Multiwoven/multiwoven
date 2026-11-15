# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::SecretMasking do
  describe "MASKED_VALUE" do
    it "equals the expected mask string" do
      expect(described_class::MASKED_VALUE).to eq("*************")
    end
  end

  describe ".mask_by_keys" do
    let(:schema) do
      {
        properties: {
          api_key: { type: "string", multiwoven_secret: true },
          password: { type: "string", multiwoven_secret: true },
          host: { type: "string" }
        }
      }
    end

    it "returns a non-hash value unchanged" do
      expect(described_class.mask_by_keys("plaintext", schema)).to eq("plaintext")
    end

    it "returns nil unchanged" do
      expect(described_class.mask_by_keys(nil, schema)).to be_nil
    end

    it "masks values whose keys are marked multiwoven_secret in schema" do
      config = { "api_key" => "real-key", "password" => "hunter2" }
      result = described_class.mask_by_keys(config, schema)
      expect(result["api_key"]).to eq("*************")
      expect(result["password"]).to eq("*************")
    end

    it "leaves values whose keys are not marked as secrets unchanged" do
      config = { "host" => "localhost", "port" => 5432 }
      result = described_class.mask_by_keys(config, schema)
      expect(result["host"]).to eq("localhost")
      expect(result["port"]).to eq(5432)
    end

    it "recurses into nested hashes" do
      nested_schema = {
        properties: {
          credentials: {
            type: "object",
            properties: {
              api_key: { type: "string", multiwoven_secret: true },
              user: { type: "string" }
            }
          }
        }
      }
      config = { "credentials" => { "api_key" => "secret", "user" => "admin" } }
      result = described_class.mask_by_keys(config, nested_schema)
      expect(result["credentials"]["api_key"]).to eq("*************")
      expect(result["credentials"]["user"]).to eq("admin")
    end

    it "recurses into arrays using schema items" do
      array_schema = {
        type: "array",
        items: {
          type: "object",
          properties: {
            api_key: { type: "string", multiwoven_secret: true },
            host: { type: "string" }
          }
        }
      }
      config = [{ "api_key" => "key1", "host" => "example.com" }, { "api_key" => "key2" }]
      result = described_class.mask_by_keys(config, array_schema)
      expect(result[0]["api_key"]).to eq("*************")
      expect(result[0]["host"]).to eq("example.com")
      expect(result[1]["api_key"]).to eq("*************")
    end

    it "returns config unchanged when schema has no multiwoven_secret fields" do
      empty_schema = { properties: { host: { type: "string" } } }
      config = { "host" => "localhost", "api_key" => "real-key" }
      result = described_class.mask_by_keys(config, empty_schema)
      expect(result).to eq(config)
    end

    it "does not mutate the original config" do
      config = { "api_key" => "original" }
      described_class.mask_by_keys(config, schema)
      expect(config["api_key"]).to eq("original")
    end

    it "does not expose extract_secret_keys publicly" do
      expect { described_class.extract_secret_keys({}) }.to raise_error(NoMethodError)
    end
  end

  describe ".mask_nested_values" do
    it "masks a non-blank string" do
      expect(described_class.mask_nested_values("sensitive")).to eq("*************")
    end

    it "leaves a blank string unchanged" do
      expect(described_class.mask_nested_values("")).to eq("")
    end

    it "returns nil unchanged" do
      expect(described_class.mask_nested_values(nil)).to be_nil
    end

    it "returns a numeric value unchanged" do
      expect(described_class.mask_nested_values(42)).to eq(42)
    end

    it "masks all string values in a hash" do
      obj = { "token" => "abc", "label" => "public" }
      result = described_class.mask_nested_values(obj)
      expect(result["token"]).to eq("*************")
      expect(result["label"]).to eq("*************")
    end

    it "recursively masks values in nested hashes" do
      obj = { "auth" => { "bearer" => "secret", "scheme" => "Bearer" } }
      result = described_class.mask_nested_values(obj)
      expect(result["auth"]["bearer"]).to eq("*************")
      expect(result["auth"]["scheme"]).to eq("*************")
    end

    it "recursively masks strings in arrays" do
      obj = ["token1", "token2", ""]
      result = described_class.mask_nested_values(obj)
      expect(result).to eq(["*************", "*************", ""])
    end

    it "handles mixed nested structures" do
      obj = { "keys" => %w[key1 key2], "meta" => { "id" => 1, "label" => "x" } }
      result = described_class.mask_nested_values(obj)
      expect(result["keys"]).to eq(["*************", "*************"])
      expect(result["meta"]["id"]).to eq(1)
      expect(result["meta"]["label"]).to eq("*************")
    end
  end

  describe ".masked_attribute_keys" do
    let(:masked) { described_class::MASKED_VALUE }

    it "returns empty array for nil" do
      expect(described_class.masked_attribute_keys(nil)).to eq([])
    end

    it "returns empty array when no values are masked" do
      expect(described_class.masked_attribute_keys({ "api_key" => "real", "limit" => 10 })).to eq([])
    end

    it "returns the masked key" do
      expect(described_class.masked_attribute_keys({ "api_key" => masked,
                                                     "limit" => 10 })).to contain_exactly("api_key")
    end

    it "returns multiple masked keys" do
      expect(described_class.masked_attribute_keys({ "api_key" => masked, "secret" => masked,
                                                     "limit" => 10 })).to contain_exactly("api_key", "secret")
    end
  end
end
