# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::OpenAI::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:mock_http_session) { double("Net::Http::Session") }
  let(:api_key) { "test_api_key" }
  let(:payload) do
    {
      queries: "Hello there"
    }
  end

  let(:sync_config_json) do
    {
      source: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {
          api_key: api_key,
          config: {
            timeout: 25
          },
          request_format: payload.to_json
        }
      },
      destination: {
        name: "Http",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "ExampleModel",
        query: payload.to_json,
        query_type: "ai_ml",
        primary_key: "id"
      },
      stream: {
        name: "example_stream",
        json_schema: { "field1": "type1" },
        request_method: "POST",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "upsert",
      sync_id: "1"
    }
  end

  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
  let(:sync_config_stream) do
    sync_config_json[:source][:connection_specification][:is_stream] = true
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
  end
  before do
    allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
  end
  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    }
  end
  let(:endpoint) { "https://api.openai.com/v1/chat/completions" }

  describe "#check_connection" do
    context "when the connection is successful" do
      let(:response_body) { { "message" => "success" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "Unauthorized")
        response.content_type = "application/json"
        config = sync_config_json[:source][:connection_specification][:config]
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers,
                options: { config: config })
          .and_return(response)
      end

      it "returns a successful connection status" do
        response = client.check_connection(sync_config_json[:source][:connection_specification])
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      let(:response_body) { { "message" => "failed" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                headers: headers)
          .and_return(response)
      end

      it "returns a failed connection status with an error message" do
        response = client.check_connection(sync_config_json[:source][:connection_specification])

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    it "successfully returns the catalog message" do
      message = client.discover(nil)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(600)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
    end

    it "handles exceptions during discovery" do
      allow(client).to receive(:read_json).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError),
        hash_including(context: "OPEN AI:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover
    end
  end

  describe "#read" do
    context "when the read is successful" do
      let(:response_body) { { "message" => "Hello! how can I help" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "200", "success")
        response.content_type = "application/json"
        config = sync_config_json[:source][:connection_specification][:config]
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers,
                options: { config: config })
          .and_return(response)
      end

      it "successfully reads records" do
        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(JSON.parse(response_body))
      end
    end

    context "when the read operation fails" do
      let(:response_body) { { "message" => "failed" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        config = sync_config_json[:source][:connection_specification][:config]
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                headers: headers,
                config: config)
          .and_return(response)
      end

      it "handles exceptions during reading" do
        error_instance = StandardError.new("test error")
        allow(client).to receive(:run_model).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          hash_including(context: "OPEN AI:READ:EXCEPTION", type: "error")
        )

        client.read(sync_config)
      end
    end
  end

  describe "#read with is_stream = true" do
    context "when the read is successful" do
      before do
        payload = sync_config_json[:model][:query]
        streaming_chunk_first = <<~DATA
          data: {"choices":[{"delta":{"content":"How I "}}]}

          data: {"choices":[{"delta":{"content":"can help "}}]}
        DATA
        streaming_chunk_second = "data: {\"choices\":[{\"delta\":{\"content\":\"you\"}}]}\n\n"

        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload),
                headers: headers,
                config: sync_config_json[:source][:connection_specification][:config])
          .and_yield(streaming_chunk_first)
          .and_yield(streaming_chunk_second)

        response = Net::HTTPSuccess.new("1.1", "200", "success")
        response.content_type = "application/json"
      end

      it "streams data and processes chunks" do
        results = []
        client.read(sync_config_stream) { |message| results << message }
        expect(results.first).to be_an(Array)
        expect(results.first.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results.first.first.record.data.dig("choices", 0, "delta", "content")).to eq("How I ")

        expect(results[1]).to be_an(Array)
        expect(results[1].first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results[1].first.record.data.dig("choices", 0, "delta", "content")).to eq("can help ")

        expect(results[2]).to be_an(Array)
        expect(results[2].first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results[2].first.record.data.dig("choices", 0, "delta", "content")).to eq("you")
      end
    end

    context "when the read is successful but failed message for open ai" do
      before do
        payload = sync_config_json[:model][:query]
        streaming_chunk_first = "{\"error\":{\"message\":\"Incorrect API key provided: sk-proj\"}}\n\n"
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload),
                headers: headers,
                config: sync_config_json[:source][:connection_specification][:config])
          .and_yield(streaming_chunk_first)

        response = Net::HTTPSuccess.new("1.1", "200", "success")
        response.content_type = "application/json"
      end

      it "streams data failed" do
        result = client.read(sync_config_stream)
        expect(result).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(result.type).to eq("log")
        expect(result.log.message).to eq("Error: Incorrect API key provided: sk-proj")
      end
    end

    context "when streaming fails on a chunk" do
      let(:streaming_chunk_first) { { "message" => "streaming data chunk 1" }.to_json }

      before do
        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(endpoint,
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers,
                config: config)
          .and_yield(streaming_chunk_first)
          .and_raise(StandardError, "Streaming error on chunk 2")
      end

      it "handles streaming errors gracefully" do
        results = []
        client.read(sync_config_stream) { |message| results << message }
        expect(results.last).to be_an(Array)
        expect(results.last.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results.last.first.record.data["message"]).to eq("streaming data chunk 1")
      end
    end
<<<<<<< HEAD
=======

    context "when chat completions rejects the model" do
      let(:config) { sync_config_json[:source][:connection_specification][:config] }
      let(:chat_payload) do
        {
          "model" => "gpt-5",
          "messages" => [{ "role" => "user", "content" => "Hi." }]
        }
      end

      before do
        sync_config_json[:model][:query] = chat_payload.to_json
        sync_config_json[:source][:connection_specification][:is_stream] = true
      end

      it "retries streaming on /v1/responses" do
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(
            endpoint,
            "POST",
            payload: hash_including("model" => "gpt-5", "stream" => true),
            headers: headers,
            config: config
          ).and_yield("{\"error\":{\"message\":\"This model is only supported in v1/responses\"}}\n\n")

        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(
            "https://api.openai.com/v1/responses",
            "POST",
            payload: hash_including(
              "model" => "gpt-5",
              "input" => [{ "role" => "user", "content" => "Hi." }],
              "stream" => true
            ),
            headers: headers,
            config: config
          ).and_yield("data: {\"type\":\"response.output_text.delta\",\"delta\":\"Hello from responses\"}\n\n")

        results = []
        client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)) do |message|
          results << message
        end

        expect(results.first.first.record.data.dig("choices", 0, "delta", "content"))
          .to eq("Hello from responses")
      end

      it "retries streaming on /v1/completions for non-chat models" do
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(
            endpoint,
            "POST",
            payload: hash_including("model" => "gpt-5", "stream" => true),
            headers: headers,
            config: config
          ).and_yield("{\"error\":{\"message\":\"This is not a chat model\"}}\n\n")

        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(
            "https://api.openai.com/v1/completions",
            "POST",
            payload: hash_including("model" => "gpt-5", "prompt" => "Hi.", "stream" => true),
            headers: headers,
            config: config
          ).and_yield("data: {\"choices\":[{\"text\":\"Hello from completions\"}]}\n\n")

        results = []
        client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)) do |message|
          results << message
        end

        expect(results.first.first.record.data.dig("choices", 0, "delta", "content"))
          .to eq("Hello from completions")
      end

      it "does not replay chunks that were already emitted before the error" do
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(
            endpoint,
            "POST",
            payload: hash_including("model" => "gpt-5", "stream" => true),
            headers: headers,
            config: config
          )
          .and_yield("data: {\"choices\":[{\"delta\":{\"content\":\"partial\"}}]}\n\n")
          .and_yield("{\"error\":{\"message\":\"This model is only supported in v1/responses\"}}\n\n")

        results = []
        client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)) do |message|
          results << message
        end

        expect(Multiwoven::Integrations::Core::StreamingHttpClient).not_to have_received(:request)
          .with("https://api.openai.com/v1/responses", any_args)
        expect(results.size).to eq(1)
        expect(results.first.first.record.data.dig("choices", 0, "delta", "content")).to eq("partial")
      end

      it "does not retry streaming when the error does not name an alternate endpoint" do
        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .once
          .and_yield("{\"error\":{\"message\":\"Incorrect API key provided\"}}\n\n")

        result = client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json))

        expect(result).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(result.log.message).to eq("Error: Incorrect API key provided")
      end
    end
  end

  describe "endpoint fallback" do
    let(:chat_payload) do
      {
        "model" => "gpt-5",
        "messages" => [{ "role" => "user", "content" => "Hello" }]
      }
    end
    let(:pro_payload) do
      {
        "model" => "gpt-5-pro",
        "messages" => [{ "role" => "user", "content" => "Hello" }]
      }
    end
    let(:config) { sync_config_json[:source][:connection_specification][:config] }

    before do
      sync_config_json[:model][:query] = chat_payload.to_json
      sync_config_json[:source][:connection_specification][:request_format] = chat_payload.to_json
    end

    it "routes -pro models straight to /v1/responses" do
      sync_config_json[:model][:query] = pro_payload.to_json
      success_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      allow(success_response).to receive(:body).and_return(
        { "output" => [{ "content" => [{ "text" => "Hi" }] }] }.to_json
      )

      expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(
          "https://api.openai.com/v1/responses",
          "POST",
          hash_including(
            payload: hash_including(
              "model" => "gpt-5-pro",
              "input" => [{ "role" => "user", "content" => "Hello" }]
            )
          )
        )
        .and_return(success_response)

      records = client.read(
        Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
      )

      expect(records.first.record.data["output"]).to be_present
    end

    it "retries on /v1/responses when chat/completions rejects the model" do
      error_response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      allow(error_response).to receive(:body).and_return(
        {
          "error" => {
            "message" => "This model is only supported in v1/responses and not in v1/chat/completions.",
            "type" => "invalid_request_error"
          }
        }.to_json
      )

      success_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      allow(success_response).to receive(:body).and_return({ "output" => [{ "content" => [{ "text" => "Hi" }] }] }.to_json)

      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(endpoint, "POST", hash_including(payload: hash_including("model" => "gpt-5")))
        .and_return(error_response)
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(
          "https://api.openai.com/v1/responses",
          "POST",
          hash_including(
            payload: hash_including(
              "model" => "gpt-5",
              "input" => [{ "role" => "user", "content" => "Hello" }]
            )
          )
        )
        .and_return(success_response)

      records = client.read(
        Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
      )

      expect(records.first.record.data["output"]).to be_present
    end

    it "retries on /v1/completions when chat/completions says the model is not a chat model" do
      error_response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      allow(error_response).to receive(:body).and_return(
        {
          "error" => {
            "message" => "This is not a chat model and thus not supported in the v1/chat/completions endpoint. Did you mean to use v1/completions?",
            "type" => "invalid_request_error"
          }
        }.to_json
      )

      success_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      allow(success_response).to receive(:body).and_return({ "choices" => [{ "text" => "Hi" }] }.to_json)

      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(endpoint, "POST", hash_including(payload: hash_including("messages")))
        .and_return(error_response)
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(
          "https://api.openai.com/v1/completions",
          "POST",
          hash_including(payload: hash_including("model" => "gpt-5", "prompt" => "Hello"))
        )
        .and_return(success_response)

      records = client.read(
        Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
      )

      expect(records.first.record.data["choices"]).to be_present
    end
  end

  describe "#meta_data" do
    it "returns the correct meta data" do
      meta_data = client.send(:meta_data)
      meta_name = client.class.to_s.split("::")[-2]
      expect(meta_data).to be_a(Hash)
      expect(meta_data[:data][:name]).to eq(meta_name)
      expect(meta_data[:data][:connector_type]).to eq("source")
      expect(meta_data[:data][:icon]).to eq("https://res.cloudinary.com/dspflukeu/image/upload/v1787608718/Multiwoven/connectors/Open_ai/icon.svg")
    end
  end

  describe "request payload normalization" do
    it "passes catalog model ids through unchanged" do
      normalized = client.send(:normalize_payload, { model: "gpt-5.1", messages: [{ role: "user", content: "Hi." }] }.to_json)

      expect(normalized["model"]).to eq("gpt-5.1")
    end
  end

  describe "endpoint fallback" do
    let(:config) { sync_config_json[:source][:connection_specification][:config] }
    let(:chat_payload) do
      {
        "model" => "gpt-5",
        "messages" => [{ "role" => "user", "content" => "Hi." }]
      }
    end

    it "retries on /v1/responses when chat completions points at that endpoint" do
      failed = response_double("400", { error: { message: "This model is only supported in v1/responses" } })
      ok = response_double("200", { id: "resp_1" })
      sync_config_json[:model][:query] = chat_payload.to_json

      expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
        endpoint,
        "POST",
        payload: hash_including("model" => "gpt-5", "messages" => chat_payload["messages"]),
        headers: headers,
        options: { config: config }
      ).and_return(failed)
      expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
        "https://api.openai.com/v1/responses",
        "POST",
        payload: hash_including(
          "model" => "gpt-5",
          "input" => [{ "role" => "user", "content" => "Hi." }]
        ),
        headers: headers,
        options: { config: config }
      ).and_return(ok)

      records = client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json))

      expect(records.first.record.data).to include("id" => "resp_1")
    end

    it "retries on /v1/completions for non-chat models" do
      failed = response_double("400", { error: { message: "This is not a chat model" } })
      ok = response_double("200", { id: "cmpl_1" })
      sync_config_json[:model][:query] = chat_payload.to_json

      expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
        endpoint,
        "POST",
        payload: hash_including("model" => "gpt-5"),
        headers: headers,
        options: { config: config }
      ).and_return(failed)
      expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
        "https://api.openai.com/v1/completions",
        "POST",
        payload: hash_including("model" => "gpt-5", "prompt" => "Hi."),
        headers: headers,
        options: { config: config }
      ).and_return(ok)

      records = client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json))

      expect(records.first.record.data).to include("id" => "cmpl_1")
    end

    it "does not retry when the error does not name an alternate endpoint" do
      failed = response_double("401", { error: { message: "Incorrect API key provided" } })
      sync_config_json[:model][:query] = chat_payload.to_json

      expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).once.and_return(failed)

      expect(client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json))).to be_a(
        Multiwoven::Integrations::Protocol::MultiwovenMessage
      )
    end

    it "resolves the fallback url from the provider error" do
      expect(client.send(:resolve_fallback_url, "Use /v1/responses instead")).to eq(
        "https://api.openai.com/v1/responses"
      )
      expect(client.send(:resolve_fallback_url, "not a chat model")).to eq(
        "https://api.openai.com/v1/completions"
      )
      expect(client.send(:resolve_fallback_url, "Did you mean to use v1/completions?")).to eq(
        "https://api.openai.com/v1/completions"
      )
      expect(client.send(:resolve_fallback_url,
                         "This model is only supported in v1/responses and not in v1/chat/completions."))
        .to eq("https://api.openai.com/v1/responses")
      expect(client.send(:resolve_fallback_url,
                         "Function tools with reasoning_effort are not supported. " \
                         "To use function tools, use /v1/responses."))
        .to eq("https://api.openai.com/v1/responses")
      expect(client.send(:resolve_fallback_url, "Incorrect API key provided")).to be_nil
      expect(client.send(:resolve_fallback_url, "")).to be_nil
    end

    it "routes -pro model ids to /v1/responses up front" do
      expect(client.send(:resolve_endpoint_url, { "model" => "gpt-5-pro" }))
        .to eq("https://api.openai.com/v1/responses")
      expect(client.send(:resolve_endpoint_url, { model: "gpt-5.6-sol-pro" }))
        .to eq("https://api.openai.com/v1/responses")
      expect(client.send(:resolve_endpoint_url, { "model" => "gpt-5" }))
        .to eq("https://api.openai.com/v1/chat/completions")
    end

    it "rewrites chat messages to input or prompt for the fallback endpoints" do
      responses = client.send(:adapt_payload_for_url, chat_payload, "https://api.openai.com/v1/responses")
      completions = client.send(:adapt_payload_for_url, chat_payload, "https://api.openai.com/v1/completions")

      expect(responses).to include(
        "model" => "gpt-5",
        "input" => [{ "role" => "user", "content" => "Hi." }]
      )
      expect(responses).not_to have_key("messages")
      expect(completions).to include("model" => "gpt-5", "prompt" => "Hi.")
      expect(completions).not_to have_key("messages")
    end

    context "with the Model Hub payload shape" do
      let(:hub_payload) do
        {
          "model" => "gpt-5",
          "messages" => [{ "role" => "system", "content" => "Be terse." }, { "role" => "user", "content" => "Hi." }],
          "max_tokens" => 16,
          "stream" => false
        }
      end

      it "renames max_tokens to max_output_tokens for /v1/responses" do
        adapted = client.send(:adapt_payload_for_url, hub_payload, "https://api.openai.com/v1/responses")

        expect(adapted["max_output_tokens"]).to eq(16)
        expect(adapted).not_to have_key("max_tokens")
        expect(adapted).not_to have_key("messages")
        expect(adapted["input"]).to eq(
          [{ "role" => "system", "content" => "Be terse." }, { "role" => "user", "content" => "Hi." }]
        )
      end

      it "keeps max_tokens for /v1/completions, which still accepts it" do
        adapted = client.send(:adapt_payload_for_url, hub_payload, "https://api.openai.com/v1/completions")

        expect(adapted["max_tokens"]).to eq(16)
        expect(adapted).not_to have_key("max_output_tokens")
        expect(adapted["prompt"]).to eq("Be terse.\nHi.")
      end

      it "drops chat-only keys that /v1/responses rejects" do
        payload = hub_payload.merge("n" => 1, "stop" => ["x"], "response_format" => { "type" => "json_object" },
                                    "frequency_penalty" => 0.1, "logprobs" => true)

        adapted = client.send(:adapt_payload_for_url, payload, "https://api.openai.com/v1/responses")

        expect(adapted.keys).not_to include("n", "stop", "response_format", "frequency_penalty", "logprobs")
      end

      it "flattens multimodal parts to text instead of inspecting them" do
        payload = { "messages" => [{ "role" => "user",
                                     "content" => [{ "type" => "text", "text" => "describe" },
                                                   { "type" => "image_url", "image_url" => { "url" => "http://x" } }] }] }

        expect(client.send(:extract_prompt_text, payload)).to eq("describe")
      end
    end
  end

  describe "SSE parsing" do
    it "reads Responses frames that are prefixed with an event: line" do
      chunk = "event: response.output_text.delta\n" \
              "data: {\"type\":\"response.output_text.delta\",\"delta\":\"Hel\"}\n\n" \
              "event: response.output_text.delta\n" \
              "data: {\"type\":\"response.output_text.delta\",\"delta\":\"lo\"}\n\n"

      entries = client.send(:extract_data_entries, chunk)

      expect(entries.size).to eq(2)
      expect(entries.map { |entry| JSON.parse(entry)["delta"] }).to eq(%w[Hel lo])
    end

    it "still reads chat completions frames" do
      chunk = "data: {\"choices\":[{\"delta\":{\"content\":\"Hi\"}}]}\n\ndata: [DONE]\n\n"

      expect(client.send(:extract_data_entries, chunk)).to eq(
        ["{\"choices\":[{\"delta\":{\"content\":\"Hi\"}}]}", "[DONE]"]
      )
    end

    it "passes an unframed error body through so the fallback can read it" do
      body = "{\"error\":{\"message\":\"This is not a chat model\"}}"

      expect(client.send(:extract_data_entries, body)).to eq([body])
    end
  end

  describe "response normalization" do
    it "leaves chat completions responses unchanged" do
      data = {
        "choices" => [
          { "index" => 0, "message" => { "role" => "assistant", "content" => "Hello" }, "finish_reason" => "stop" }
        ]
      }

      expect(client.send(:normalize_response_data, data)).to eq(data)
    end

    it "maps completions text choices into message.content" do
      data = {
        "choices" => [
          { "index" => 0, "text" => "Hello from completions", "finish_reason" => "stop" }
        ]
      }

      normalized = client.send(:normalize_response_data, data)

      expect(normalized.dig("choices", 0, "message")).to eq(
        "role" => "assistant",
        "content" => "Hello from completions"
      )
    end

    it "maps Responses API output into choices[].message.content" do
      data = {
        "object" => "response",
        "status" => "completed",
        "output" => [
          {
            "type" => "message",
            "role" => "assistant",
            "content" => [
              { "type" => "output_text", "text" => "Hello from responses" }
            ]
          }
        ]
      }

      normalized = client.send(:normalize_response_data, data)

      expect(normalized.dig("choices", 0, "message", "content")).to eq("Hello from responses")
      expect(normalized.dig("choices", 0, "finish_reason")).to eq("stop")
    end

    it "joins multiple text parts from a Responses API output" do
      data = {
        "object" => "response",
        "output" => [
          {
            "type" => "message",
            "content" => [
              { "type" => "output_text", "text" => "Hello " },
              { "type" => "output_text", "text" => "world" }
            ]
          }
        ]
      }

      expect(client.send(:normalize_response_data, data).dig("choices", 0, "message", "content"))
        .to eq("Hello world")
    end

    it "does not invent choices when Responses API output has no text" do
      data = {
        "object" => "response",
        "output" => [{ "type" => "reasoning", "content" => [{ "type" => "reasoning_text", "text" => "thinking" }] }]
      }

      expect(client.send(:normalize_response_data, data)).to eq(data)
    end

    it "returns chat-shaped data from read when the Responses API succeeds" do
      sync_config_json[:model][:query] = {
        "model" => "gpt-5",
        "messages" => [{ "role" => "user", "content" => "Hi." }]
      }.to_json
      failed = response_double("400", { error: { message: "Use /v1/responses" } })
      ok = response_double(
        "200",
        {
          "object" => "response",
          "status" => "completed",
          "output" => [
            {
              "type" => "message",
              "content" => [{ "type" => "output_text", "text" => "Normalized hello" }]
            }
          ]
        }
      )

      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(endpoint, "POST", hash_including(headers: headers))
        .and_return(failed)
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with("https://api.openai.com/v1/responses", "POST", hash_including(headers: headers))
        .and_return(ok)

      records = client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json))

      expect(records.first.record.data.dig("choices", 0, "message", "content")).to eq("Normalized hello")
    end

    it "returns chat-shaped data from read when the Completions API succeeds" do
      sync_config_json[:model][:query] = {
        "model" => "gpt-5",
        "messages" => [{ "role" => "user", "content" => "Hi." }]
      }.to_json
      failed = response_double("400", { error: { message: "This is not a chat model" } })
      ok = response_double(
        "200",
        {
          "choices" => [
            { "index" => 0, "text" => "Normalized completions", "finish_reason" => "stop" }
          ]
        }
      )

      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(endpoint, "POST", hash_including(headers: headers))
        .and_return(failed)
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with("https://api.openai.com/v1/completions", "POST", hash_including(headers: headers))
        .and_return(ok)

      records = client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json))

      expect(records.first.record.data.dig("choices", 0, "message", "content")).to eq("Normalized completions")
    end

    it "maps Responses API stream deltas into chat delta content" do
      data = client.send(
        :normalize_streaming_data,
        { "type" => "response.output_text.delta", "delta" => "Hello" }
      )

      expect(data.dig("choices", 0, "delta", "content")).to eq("Hello")
    end

    it "skips non-text Responses API stream events" do
      expect(client.send(:normalize_streaming_data, { "type" => "response.created" })).to be_nil
    end

    it "maps completions stream text choices into delta content" do
      data = client.send(
        :normalize_streaming_data,
        { "choices" => [{ "index" => 0, "text" => "Hello" }] }
      )

      expect(data.dig("choices", 0, "delta", "content")).to eq("Hello")
    end
>>>>>>> 74088209e (chore(CE): Add model exclusion for deprecated/unsupported models (#2219))
  end
end
