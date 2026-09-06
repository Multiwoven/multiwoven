# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::JsonRpcClient do
  let(:url) { "https://api.example.com/rpc" }
  let(:uri) { URI.parse(url) }

  it "inherits from Utils::HttpClient" do
    expect(described_class).to be < Utils::HttpClient
  end

  describe ".build_jsonrpc_envelope" do
    it "builds a valid JSON-RPC 2.0 envelope" do
      envelope = described_class.build_jsonrpc_envelope("test_method", { key: "value" }, id: 42)

      expect(envelope[:jsonrpc]).to eq("2.0")
      expect(envelope[:method]).to eq("test_method")
      expect(envelope[:params]).to eq({ key: "value" })
      expect(envelope[:id]).to eq(42)
    end

    it "generates a random id when not provided" do
      envelope = described_class.build_jsonrpc_envelope("test_method")

      expect(envelope[:id]).to be_a(Integer)
      expect(envelope[:id]).to be_between(1, 2_147_483_647)
    end

    it "defaults params to empty hash" do
      envelope = described_class.build_jsonrpc_envelope("test_method")

      expect(envelope[:params]).to eq({})
    end
  end

  describe ".build_http_client" do
    it "creates an HTTP client with SSL for https URLs" do
      http = described_class.build_http_client(uri)

      expect(http).to be_a(Net::HTTP)
      expect(http.use_ssl?).to be(true)
      expect(http.open_timeout).to eq(30)
      expect(http.read_timeout).to eq(30)
    end

    it "uses custom timeout" do
      http = described_class.build_http_client(uri, timeout: 60)

      expect(http.open_timeout).to eq(60)
      expect(http.read_timeout).to eq(60)
    end

    it "uses separate read_timeout when provided" do
      http = described_class.build_http_client(uri, timeout: 30, read_timeout: 120)

      expect(http.open_timeout).to eq(30)
      expect(http.read_timeout).to eq(120)
    end

    it "does not use SSL for http URLs" do
      http_uri = URI.parse("http://api.example.com/rpc")
      http = described_class.build_http_client(http_uri)

      expect(http.use_ssl?).to be(false)
    end
  end

  describe ".build_post_request" do
    it "creates a POST request with JSON-RPC body" do
      request = described_class.build_post_request(uri, "test_method", { key: "value" }, id: 1)

      expect(request).to be_a(Net::HTTP::Post)
      expect(request["Content-Type"]).to eq("application/json")
      expect(request["Accept"]).to eq("application/json")

      body = JSON.parse(request.body)
      expect(body["jsonrpc"]).to eq("2.0")
      expect(body["method"]).to eq("test_method")
      expect(body["params"]).to eq({ "key" => "value" })
      expect(body["id"]).to eq(1)
    end

    it "includes custom headers" do
      request = described_class.build_post_request(
        uri, "test_method", {}, headers: { "Authorization" => "Bearer token123" }
      )

      expect(request["Authorization"]).to eq("Bearer token123")
    end
  end

  describe ".parse_jsonrpc_response" do
    context "with successful JSON-RPC response" do
      let(:response) do
        instance_double(Net::HTTPSuccess,
                        code: "200",
                        body: { "jsonrpc" => "2.0", "id" => 1, "result" => "ok" }.to_json)
      end

      before { allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) }

      it "returns success with parsed body, status, and raw" do
        result = described_class.parse_jsonrpc_response(response)

        expect(result[:success]).to be(true)
        expect(result[:status]).to eq("200")
        expect(result[:raw]).to eq(response.body)
        expect(result[:body]["result"]).to eq("ok")
      end
    end

    context "with JSON-RPC error response" do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          code: "200",
          body: { "jsonrpc" => "2.0", "id" => 1, "error" => { "code" => -32_600, "message" => "Invalid" } }.to_json
        )
      end

      before { allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) }

      it "returns failure when body contains error key" do
        result = described_class.parse_jsonrpc_response(response)

        expect(result[:success]).to be(false)
        expect(result[:status]).to eq("200")
        expect(result[:body]["error"]["message"]).to eq("Invalid")
      end
    end

    context "with HTTP failure response" do
      let(:response) do
        instance_double(
          Net::HTTPInternalServerError,
          code: "500",
          body: { "jsonrpc" => "2.0", "id" => 1, "result" => "data" }.to_json
        )
      end

      before { allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false) }

      it "returns failure with status and raw" do
        result = described_class.parse_jsonrpc_response(response)

        expect(result[:success]).to be(false)
        expect(result[:status]).to eq("500")
        expect(result[:raw]).to eq(response.body)
      end
    end

    context "with invalid JSON body" do
      let(:response) { instance_double(Net::HTTPSuccess, code: "200", body: "not valid json") }

      before { allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) }

      it "returns failure with status, raw, and error message" do
        result = described_class.parse_jsonrpc_response(response)

        expect(result[:success]).to be(false)
        expect(result[:status]).to eq("200")
        expect(result[:raw]).to eq("not valid json")
        expect(result[:body]["error"]["message"]).to eq("Invalid JSON response")
      end
    end

    context "with non-object JSON body" do
      ["[1,2,3]", "\"just_a_string\"", "42", "true", "null"].each do |payload|
        it "rejects #{payload} with status and raw" do
          resp = instance_double(Net::HTTPSuccess, code: "200", body: payload)
          allow(resp).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

          result = described_class.parse_jsonrpc_response(resp)

          expect(result[:success]).to be(false)
          expect(result[:status]).to eq("200")
          expect(result[:raw]).to eq(payload)
          expect(result[:body]["error"]["message"]).to include("expected object")
        end
      end
    end

    it "accepts an optional body parameter" do
      response = instance_double(Net::HTTPSuccess, code: "200", body: "ignored")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      override_body = { "jsonrpc" => "2.0", "id" => 1, "result" => "override" }.to_json

      result = described_class.parse_jsonrpc_response(response, body: override_body)

      expect(result[:success]).to be(true)
      expect(result[:raw]).to eq(override_body)
      expect(result[:body]["result"]).to eq("override")
    end
  end

  describe ".parse_response" do
    context "with successful response" do
      let(:response) do
        instance_double(Net::HTTPSuccess, code: "200", body: { "data" => "value" }.to_json)
      end

      before { allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) }

      it "returns success with parsed body" do
        result = described_class.parse_response(response)

        expect(result[:success]).to be(true)
        expect(result[:body]).to eq({ "data" => "value" })
      end
    end

    context "with failure response" do
      let(:response) do
        instance_double(Net::HTTPInternalServerError, code: "500", body: { "error" => "fail" }.to_json)
      end

      before { allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false) }

      it "returns failure" do
        result = described_class.parse_response(response)

        expect(result[:success]).to be(false)
      end
    end

    context "with unparseable body" do
      let(:response) do
        instance_double(Net::HTTPSuccess, code: "200", body: "not json")
      end

      before { allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true) }

      it "returns empty hash as body" do
        result = described_class.parse_response(response)

        expect(result[:success]).to be(true)
        expect(result[:body]).to eq({})
      end
    end
  end

  describe ".execute_rpc" do
    before do
      allow(described_class).to receive(:post).and_return(
        { "jsonrpc" => "2.0", "id" => 1, "result" => "done" }
      )
    end

    it "delegates to inherited post and returns wrapped result" do
      result = described_class.execute_rpc(url:, method: "test_method", params: { key: "val" })

      expect(described_class).to have_received(:post).with(
        base_url: url,
        headers: hash_including("Accept" => "application/json"),
        body: hash_including(jsonrpc: "2.0", method: "test_method", params: { key: "val" }),
        config: { timeout: 30, open_timeout: 30 }
      )
      expect(result[:success]).to be(true)
      expect(result[:body]["result"]).to eq("done")
    end

    it "passes custom headers" do
      described_class.execute_rpc(url:, method: "m", headers: { "X-Custom" => "val" })

      expect(described_class).to have_received(:post).with(
        hash_including(headers: hash_including("X-Custom" => "val"))
      )
    end

    it "uses timeout from config" do
      described_class.execute_rpc(url:, method: "m", config: { timeout: 90 })

      expect(described_class).to have_received(:post).with(
        hash_including(config: { timeout: 90, open_timeout: 90 })
      )
    end

    it "threads read_timeout from config to HttpClient" do
      described_class.execute_rpc(url:, method: "m", config: { timeout: 30, read_timeout: 120 })

      expect(described_class).to have_received(:post).with(
        hash_including(config: { timeout: 120, open_timeout: 30 })
      )
    end

    it "returns error hash for malformed URLs" do
      result = described_class.execute_rpc(url: "ht tp://bad url", method: "m")

      expect(result[:success]).to be(false)
      expect(result[:body]["error"]["message"]).to include("Transport error")
    end

    it "returns error hash for unsupported URI schemes" do
      result = described_class.execute_rpc(url: "ftp://files.example.com/data", method: "m")

      expect(result[:success]).to be(false)
      expect(result[:body]["error"]["message"]).to include("Unsupported URI scheme")
    end

    it "returns failure when response contains error key" do
      allow(described_class).to receive(:post).and_return(
        { "jsonrpc" => "2.0", "id" => 1, "error" => { "code" => -32_600, "message" => "Invalid" } }
      )

      result = described_class.execute_rpc(url:, method: "m")

      expect(result[:success]).to be(false)
      expect(result[:body]["error"]["message"]).to eq("Invalid")
    end

    it "returns failure when response is not a Hash" do
      allow(described_class).to receive(:post).and_return([1, 2, 3])

      result = described_class.execute_rpc(url:, method: "m")

      expect(result[:success]).to be(false)
      expect(result[:body]["error"]["message"]).to include("expected object")
    end

    it "propagates transport errors for Connection#handle_request_errors" do
      allow(described_class).to receive(:post).and_raise(Errno::ECONNREFUSED)

      expect { described_class.execute_rpc(url:, method: "m") }.to raise_error(Errno::ECONNREFUSED)
    end

    it "propagates timeout errors for Connection#handle_request_errors" do
      allow(described_class).to receive(:post).and_raise(Timeout::Error, "timed out")

      expect { described_class.execute_rpc(url:, method: "m") }.to raise_error(Timeout::Error)
    end
  end

  describe ".execute_get" do
    before do
      allow(described_class).to receive(:get).and_return({ "status" => "ok" })
    end

    it "delegates to inherited get and returns wrapped result" do
      result = described_class.execute_get(url:)

      expect(described_class).to have_received(:get).with(
        base_url: url,
        headers: hash_including("Accept" => "application/json"),
        config: { timeout: 30, open_timeout: 30 }
      )
      expect(result[:success]).to be(true)
      expect(result[:body]).to eq({ "status" => "ok" })
    end

    it "passes custom headers" do
      described_class.execute_get(url:, headers: { "Authorization" => "Bearer token" })

      expect(described_class).to have_received(:get).with(
        hash_including(headers: hash_including("Authorization" => "Bearer token"))
      )
    end

    it "uses timeout from config" do
      described_class.execute_get(url:, config: { timeout: 120 })

      expect(described_class).to have_received(:get).with(
        hash_including(config: { timeout: 120, open_timeout: 120 })
      )
    end

    it "threads read_timeout from config to HttpClient" do
      described_class.execute_get(url:, config: { timeout: 30, read_timeout: 90 })

      expect(described_class).to have_received(:get).with(
        hash_including(config: { timeout: 90, open_timeout: 30 })
      )
    end

    it "returns error hash for malformed URLs" do
      result = described_class.execute_get(url: "ht tp://bad url")

      expect(result[:success]).to be(false)
      expect(result[:body]["error"]["message"]).to include("Transport error")
    end

    it "returns error hash for unsupported URI schemes" do
      result = described_class.execute_get(url: "ftp://files.example.com/data")

      expect(result[:success]).to be(false)
      expect(result[:body]["error"]["message"]).to include("Unsupported URI scheme")
    end

    it "returns failure when response contains error key" do
      allow(described_class).to receive(:get).and_return(
        { "error" => { "message" => "Not found" } }
      )

      result = described_class.execute_get(url:)

      expect(result[:success]).to be(false)
      expect(result[:body]["error"]["message"]).to eq("Not found")
    end

    it "propagates transport errors for Connection#handle_request_errors" do
      allow(described_class).to receive(:get).and_raise(Errno::ECONNREFUSED)

      expect { described_class.execute_get(url:) }.to raise_error(Errno::ECONNREFUSED)
    end

    it "propagates timeout errors for Connection#handle_request_errors" do
      allow(described_class).to receive(:get).and_raise(Timeout::Error, "timed out")

      expect { described_class.execute_get(url:) }.to raise_error(Timeout::Error)
    end
  end

  describe ".handle_response" do
    it "returns parsed body for 2xx responses" do
      response = instance_double(Net::HTTPSuccess, code: "200",
                                                   body: { "result" => "ok" }.to_json)

      result = described_class.handle_response(response)

      expect(result).to eq({ "result" => "ok" })
    end

    it "returns empty hash for 2xx with blank body" do
      response = instance_double(Net::HTTPSuccess, code: "200", body: "")

      result = described_class.handle_response(response)

      expect(result).to eq({})
    end

    it "preserves error key from non-2xx JSON-RPC response" do
      response = instance_double(Net::HTTPBadRequest, code: "400",
                                                      body: { "error" => { "message" => "Bad request" } }.to_json)

      result = described_class.handle_response(response)

      expect(result["error"]["message"]).to eq("Bad request")
    end

    it "adds synthetic error for non-2xx without error key" do
      response = instance_double(Net::HTTPInternalServerError, code: "500",
                                                               body: { "data" => "value" }.to_json)

      result = described_class.handle_response(response)

      expect(result["error"]["message"]).to eq("HTTP request failed with status 500")
      expect(result["data"]).to eq("value")
    end

    it "handles non-2xx with empty body" do
      response = instance_double(Net::HTTPInternalServerError, code: "500", body: "")

      result = described_class.handle_response(response)

      expect(result["error"]["message"]).to eq("HTTP request failed with status 500")
    end

    it "handles non-2xx with non-JSON body" do
      response = instance_double(Net::HTTPInternalServerError, code: "500",
                                                               body: "<html>Server Error</html>")

      result = described_class.handle_response(response)

      expect(result["error"]["message"]).to eq("HTTP request failed with status 500")
    end
  end

  describe ".post (error unwrapping)" do
    it "re-raises original exception from HttpClient RuntimeError wrapper" do
      allow(Utils::HttpClient).to receive(:post).and_raise(
        RuntimeError.new("HTTP request failed: Connection refused").tap do |e|
          # Simulate Ruby's cause mechanism
          allow(e).to receive(:cause).and_return(Errno::ECONNREFUSED.new)
        end
      )

      expect { described_class.post(base_url: url) }.to raise_error(Errno::ECONNREFUSED)
    end
  end

  describe ".get (error unwrapping)" do
    it "re-raises original exception from HttpClient RuntimeError wrapper" do
      allow(Utils::HttpClient).to receive(:get).and_raise(
        RuntimeError.new("HTTP request failed: Connection refused").tap do |e|
          allow(e).to receive(:cause).and_return(Errno::ECONNREFUSED.new)
        end
      )

      expect { described_class.get(base_url: url) }.to raise_error(Errno::ECONNREFUSED)
    end
  end
end
