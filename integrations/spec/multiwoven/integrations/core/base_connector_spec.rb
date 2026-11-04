# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe BaseConnector do
      describe "#connector_spec" do
        xit "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.connector_spec }.to raise_error("Not implemented")
        end
      end

      describe "#check_connection" do
        it "raises an error" do
          expect { described_class.new.check_connection({}) }.to raise_error("Not implemented")
        end
      end

      describe "#discover" do
        it "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.discover({}) }.to raise_error("Not implemented")
        end
      end
<<<<<<< HEAD
=======

      describe "#http_error_message" do
        let(:connector) { SourceConnector.new }

        it "returns failed when the response is nil" do
          expect(connector.send(:http_error_message, nil)).to eq("failed")
        end

        it "extracts nested provider error messages" do
          response = instance_double(Net::HTTPResponse, body: { error: { message: "Invalid API key" } }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("Invalid API key")
        end

        it "extracts the first message from an errors array" do
          response = instance_double(
            Net::HTTPResponse,
            body: { errors: [{ message: "Invalid authentication token" }] }.to_json
          )

          expect(connector.send(:http_error_message, response)).to eq("Invalid authentication token")
        end

        it "returns a scalar error value" do
          response = instance_double(Net::HTTPResponse, body: { error: "quota exceeded" }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("quota exceeded")
        end

        it "falls back to the raw body for a JSON array" do
          response = instance_double(Net::HTTPResponse, body: [{ code: 500 }].to_json)

          expect(connector.send(:http_error_message, response)).to eq('[{"code":500}]')
        end

        it "falls back to the raw body for a JSON scalar" do
          response = instance_double(Net::HTTPResponse, body: '"service unavailable"')

          expect(connector.send(:http_error_message, response)).to eq('"service unavailable"')
        end

        it "falls back to the raw body when the response is not JSON" do
          response = instance_double(Net::HTTPResponse, body: "service unavailable")

          expect(connector.send(:http_error_message, response)).to eq("service unavailable")
        end

        it "extracts the first entry when error is an array of strings" do
          response = instance_double(Net::HTTPResponse, body: { error: ["bad key"] }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("bad key")
        end

        it "prefers error_description over a bare OAuth error code" do
          response = instance_double(
            Net::HTTPResponse,
            body: { error: "invalid_client", error_description: "Client authentication failed" }.to_json
          )

          expect(connector.send(:http_error_message, response)).to eq("Client authentication failed")
        end

        it "reads error_description when no error key is present" do
          response = instance_double(Net::HTTPResponse, body: { error_description: "Token expired" }.to_json)

          expect(connector.send(:http_error_message, response)).to eq("Token expired")
        end

        it "reports the status code instead of dumping an HTML error page" do
          response = instance_double(
            Net::HTTPResponse,
            body: "<!DOCTYPE html><html><body>#{"Attention Required " * 500}</body></html>",
            code: "403"
          )

          expect(connector.send(:http_error_message, response)).to eq("HTTP 403")
        end

        it "caps an oversized plain-text body" do
          response = instance_double(Net::HTTPResponse, body: "z" * 2_000, code: "502")

          message = connector.send(:http_error_message, response)

          expect(message.length).to eq(500)
          expect(message).to end_with("...")
        end

        it "reports the status code when the body is blank" do
          response = instance_double(Net::HTTPResponse, body: "", code: "504")

          expect(connector.send(:http_error_message, response)).to eq("HTTP 504")
        end

        it "survives a body with invalid UTF-8 bytes" do
          response = instance_double(Net::HTTPResponse, body: "bad \xC3 byte".dup.force_encoding("UTF-8"), code: "500")

          expect { connector.send(:http_error_message, response) }.not_to raise_error
        end

        it "does not leak a Ruby error when reading the body raises" do
          response = instance_double(Net::HTTPResponse, code: "500")
          allow(response).to receive(:body).and_raise(IOError, "connection reset")

          expect(connector.send(:http_error_message, response)).to eq("HTTP 500")
        end
      end

      describe "#failure_status_from_response" do
        let(:connector) { SourceConnector.new }

        it "returns a failed connection status with the parsed provider message" do
          response = instance_double(
            Net::HTTPResponse,
            body: { error: { message: "Your credit balance is too low" } }.to_json
          )

          message = connector.send(:failure_status_from_response, response)

          expect(message.connection_status.status).to eq("failed")
          expect(message.connection_status.message).to include("credit balance is too low")
        end
      end

      describe "#embedding_model?" do
        let(:connector) { SourceConnector.new }

        it "detects embeddings by type or model_type" do
          expect(connector.send(:embedding_model?, { type: "embedding", model_type: "llm" })).to be(true)
          expect(connector.send(:embedding_model?, { type: "completion", model_type: "embedding" })).to be(true)
          expect(connector.send(:embedding_model?, { "model_type" => "embedding" })).to be(true)
        end

        it "does not flag other kinds" do
          expect(connector.send(:embedding_model?, { type: "completion", model_type: "llm" })).to be(false)
          expect(connector.send(:embedding_model?, { type: "image", model_type: "vision" })).to be(false)
        end
      end

      describe "#include_model?" do
        let(:connector) { SourceConnector.new }

        it "keeps kinds a connector can serve" do
          expect(connector.send(:include_model?, { model_type: "embedding", type: "embedding" })).to be(true)
          expect(connector.send(:include_model?, { model_type: "llm", type: "completion" })).to be(true)
          expect(connector.send(:include_model?, { model_type: "vision", type: "completion" })).to be(true)
        end

        it "drops image generation models" do
          expect(connector.send(:include_model?, { model_type: "vision", type: "image" })).to be(false)
          expect(connector.send(:include_model?, { "type" => "image" })).to be(false)
        end

        it "drops OpenAI models listed in OPENAI_EXCLUDE_MODELS" do
          stub_const("Multiwoven::Integrations::Core::Constants::OPENAI_EXCLUDE_MODELS",
                     "gpt-4-turbo-preview,o3-mini-high")

          expect(connector.send(:include_model?, {
                                  id: "gpt-4-turbo-preview",
                                  openrouter_id: "openai/gpt-4-turbo-preview",
                                  model_type: "llm"
                                })).to be(false)
          expect(connector.send(:include_model?, {
                                  id: "gpt-4o",
                                  openrouter_id: "openai/gpt-4o",
                                  model_type: "llm"
                                })).to be(true)
        end

        it "drops Anthropic models below ANTHROPIC_EXCLUDE_MODELS" do
          stub_const("Multiwoven::Integrations::Core::Constants::ANTHROPIC_EXCLUDE_MODELS", "4")

          expect(connector.send(:include_model?, {
                                  id: "claude-3-haiku",
                                  openrouter_id: "anthropic/claude-3-haiku",
                                  model_type: "llm"
                                })).to be(false)
          expect(connector.send(:include_model?, {
                                  id: "claude-sonnet-4.5",
                                  openrouter_id: "anthropic/claude-sonnet-4.5",
                                  model_type: "llm"
                                })).to be(true)
        end
      end

      describe "#excluded_model?" do
        let(:connector) { SourceConnector.new }

        it "matches OpenAI model ids from the comma-separated exclude list" do
          stub_const("Multiwoven::Integrations::Core::Constants::OPENAI_EXCLUDE_MODELS",
                     "gpt-4-turbo-preview, o3-mini-high")

          expect(connector.send(:excluded_model?, {
                                  id: "gpt-4-turbo-preview",
                                  openrouter_id: "openai/gpt-4-turbo-preview"
                                })).to be(true)
          expect(connector.send(:excluded_model?, {
                                  id: "gpt-4o",
                                  openrouter_id: "openai/gpt-4o"
                                })).to be(false)
        end

        it "excludes Anthropic models whose family version is below the threshold" do
          stub_const("Multiwoven::Integrations::Core::Constants::ANTHROPIC_EXCLUDE_MODELS", "4.1")

          expect(connector.send(:excluded_model?, {
                                  id: "claude-sonnet-4",
                                  openrouter_id: "anthropic/claude-sonnet-4"
                                })).to be(true)
          expect(connector.send(:excluded_model?, {
                                  id: "claude-3-haiku",
                                  openrouter_id: "anthropic/claude-3-haiku"
                                })).to be(true)
          expect(connector.send(:excluded_model?, {
                                  id: "claude-opus-4.1",
                                  openrouter_id: "anthropic/claude-opus-4.1"
                                })).to be(false)
          expect(connector.send(:excluded_model?, {
                                  id: "claude-opus-5",
                                  openrouter_id: "anthropic/claude-opus-5"
                                })).to be(false)
        end

        it "parses dated and hyphenated Anthropic ids as family versions" do
          stub_const("Multiwoven::Integrations::Core::Constants::ANTHROPIC_EXCLUDE_MODELS", "4.1")

          # dated snapshot after family.version → 4.5, keep
          expect(connector.send(:excluded_model?, {
                                  id: "claude-haiku-4-5-20251001",
                                  openrouter_id: "anthropic/claude-haiku-4.5"
                                })).to be(false)
          # dated snapshot after major only → 4, exclude
          expect(connector.send(:excluded_model?, {
                                  id: "claude-sonnet-4-20250514",
                                  openrouter_id: "anthropic/claude-sonnet-4"
                                })).to be(true)
          # legacy dated id → 3.5, exclude
          expect(connector.send(:excluded_model?, {
                                  id: "claude-3-5-sonnet-20241022",
                                  openrouter_id: "anthropic/claude-3.5-sonnet"
                                })).to be(true)
          # hyphenated 4.1 → keep at threshold 4.1
          expect(connector.send(:excluded_model?, {
                                  id: "claude-opus-4-1",
                                  openrouter_id: "anthropic/claude-opus-4.1"
                                })).to be(false)
        end

        it "compares Anthropic versions with Gem::Version, not Float" do
          stub_const("Multiwoven::Integrations::Core::Constants::ANTHROPIC_EXCLUDE_MODELS", "4.10")

          # Float would treat 4.1 == 4.10; Gem::Version keeps 4.1 below 4.10.
          expect(connector.send(:excluded_model?, {
                                  id: "claude-opus-4.1",
                                  openrouter_id: "anthropic/claude-opus-4.1"
                                })).to be(true)
          expect(connector.send(:excluded_model?, {
                                  id: "claude-opus-4-10",
                                  openrouter_id: "anthropic/claude-opus-4.10"
                                })).to be(false)
        end

        it "does not raise when Anthropic model id is nil" do
          stub_const("Multiwoven::Integrations::Core::Constants::ANTHROPIC_EXCLUDE_MODELS", "4")

          expect(connector.send(:excluded_model?, {
                                  id: nil,
                                  openrouter_id: "anthropic/claude-sonnet-4"
                                })).to be(false)
        end

        it "is false when openrouter_id is missing or from another provider" do
          stub_const("Multiwoven::Integrations::Core::Constants::OPENAI_EXCLUDE_MODELS", "gpt-4o")
          stub_const("Multiwoven::Integrations::Core::Constants::ANTHROPIC_EXCLUDE_MODELS", "99")

          expect(connector.send(:excluded_model?, { id: "gpt-4o" })).to be(false)
          expect(connector.send(:excluded_model?, {
                                  id: "bolt-instruct-32b",
                                  openrouter_id: "aisquared/bolt-instruct-32b"
                                })).to be(false)
        end
      end
>>>>>>> a0c1860c6 (chore(CE): Change OPEN_AI_EXCLUDE_MODELS to OPENAI_EXCLUDE_MODELS (#2223))
    end
  end
end
