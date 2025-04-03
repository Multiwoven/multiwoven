# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::WatsonxAi::Client do
  let(:client) { Multiwoven::Integrations::Source::WatsonxAi::Client.new }
  let(:payload) do
    {
      input_data: [
        {
          fields: %w[FIELD1 FIELD2 FIELD3],
          values: [
            %w[
              value1 value2 value3
            ]
          ]
        }
      ]
    }
  end
  let(:api_key) { "test_api_key" }
  let(:sync_config_json) do
    {
      source: {
        name: "WatsonX AI Model",
        type: "source",
        connection_specification: {
          api_key: api_key,
          region: "us-south",
          deployment_id: "Test-Deployment-Id",
          config: { "timeout": 30 },
          request_format: {},
          response_format: {},
          model_type: "Machine learning model",
          is_stream: false
        }
      },
      destination: {
        name: "Sample Destination Connector",
        type: "destination",
        connection_specification: {
          example_destination_key: "example_destination_value"
        }
      },
      model: {
        name: "WatsonX AI Account",
        query: payload.to_json,
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "example_stream",
        action: "create",
        json_schema: { "field1": "type1" },
        supported_sync_modes: %w[full_refresh incremental],
        source_defined_cursor: true,
        default_cursor_field: ["field1"],
        source_defined_primary_key: [["field1"], ["field2"]],
        namespace: "exampleNamespace",
        url: "https://api.example.com/data",
        method: "GET"
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
    sync_config_json[:source][:connection_specification][:model_type] = "Prompt template"
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
  let(:health_endpoint) { "https://us-south.ml.cloud.ibm.com/ml/v4/deployments?version=2021-05-01" }
  let(:prediction_endpoint) { "https://us-south.ml.cloud.ibm.com/ml/v4/deployments/Test-Deployment-Id/predictions?version=2021-05-01" }
  let(:stream_endpoint) { "https://us-south.ml.cloud.ibm.com/ml/v1/deployments/Test-Deployment-Id/text/generation_stream?version=2021-05-01" }

  describe "#check_connection" do
    context "when the connection is successful" do
      let(:response_body) do
        {
          "resources" => [
            {
              "metadata" => { "id" => "Test-Deployment-Id" },
              "entity" => { "status" => { "state" => "ready" } }
            }
          ]
        }.to_json
      end
      before do
        stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
          .with(
            body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            }
          ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })
        response = Net::HTTPSuccess.new("1.1", "200", "OK")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)

        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(health_endpoint, "GET", payload: {}, headers: headers, config: config)
          .and_return(response)
      end

      it "returns a successful connection status" do
        response = client.check_connection(sync_config_json[:source][:connection_specification])
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      let(:response_body) do
        {
          "resources" => [
            {
              "metadata" => { "id" => "Test-Deployment-Id" },
              "entity" => { "status" => { "state" => "disabled" } }
            }
          ]
        }.to_json
      end
      before do
        stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
          .with(
            body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            }
          ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })
        response = Net::HTTPSuccess.new("1.1", "400", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)

        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(health_endpoint, "GET", payload: {}, headers: headers, config: config)
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
      expect(catalog.request_rate_limit).to eql(120)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
    end

    it "handles exceptions during discovery" do
      allow(client).to receive(:read_json).and_raise(StandardError.new("test error"))
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError),
        hash_including(context: "WATSONX AI:DISCOVER:EXCEPTION", type: "error")
      )
      client.discover(nil)
    end
  end

  # read and #discover tests for AWS Athena
  describe "#read" do
    context "when the read is successful" do
      let(:response_body) do
        {
          "predictions": [
            {
              "fields": %w[prediction probability],
              "values": [["Missed Payment", [0.67, 0.33]]]
            }
          ]
        }.to_json
      end
      before do
        stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
          .with(
            body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            }
          ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })
        response = Net::HTTPSuccess.new("1.1", "200", "OK")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)

        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(prediction_endpoint, "POST", payload: JSON.parse(payload.to_json), headers: headers, config: config)
          .and_return(response)
      end
      it "reads records successfully" do
        allow(client).to receive(:get_access_token) do
          client.instance_variable_set(:@access_token, api_key)
        end
        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data).to eq(JSON.parse(response_body))
      end
    end

    context "when the read is failed" do
      let(:response_body) do
        {
          "error": [
            {
              "message": "Model invocation failed"
            }
          ]
        }.to_json
      end
      let(:error_instance) { StandardError.new("WatsonX API error") }
      before do
        stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
          .with(
            body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            }
          ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })
        response = Net::HTTPSuccess.new("1.1", "400", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)

        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(prediction_endpoint, "POST", payload: JSON.parse(payload.to_json), headers: headers, config: config)
          .and_return(response)
      end
      it "handles exceptions during reading" do
        allow(client).to receive(:run_model).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          {
            context: "WATSONX AI:READ:EXCEPTION",
            type: "error"
          }
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
          id: 1
          event: message
          data: {"model_id":"ibm/granite-3-8b-instruct","model_version":"1.1.0","created_at":"2025-03-13T23:45:22.678Z","results":[{"generated_text":" (2018)","generated_token_count":8,"input_token_count":1,"stop_reason":"not_finished","seed":0}]}

          id: 10
          event: message
          data: {"model_id":"ibm/granite-3-8b-instruct","model_version":"1.1.0","created_at":"2025-03-13T23:45:25.234Z","results":[{"generated_text":" The goal","generated_token_count":200,"input_token_count":0,"stop_reason":"max_tokens","seed":0}]}
        DATA

        stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
          .with(
            body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            }
          ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })

        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(stream_endpoint,
                "POST",
                payload: JSON.parse(payload),
                headers: headers,
                config: sync_config_json[:source][:connection_specification][:config])
          .and_yield(streaming_chunk_first)

        response = Net::HTTPSuccess.new("1.1", "200", "success")
        response.content_type = "application/json"
      end

      it "streams data and processes chunks" do
        results = []
        allow(client).to receive(:get_access_token) do
          client.instance_variable_set(:@access_token, api_key)
        end
        client.read(sync_config_stream) { |message| results << message }
        expect(results.first).to be_an(Array)
        expect(results.first.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results.first.first.record.data.dig("results", 0, "generated_text")).to eq(" (2018)")
      end
    end

    context "when the read is successful but failed message for WatsonX AI" do
      before do
        payload = sync_config_json[:model][:query]
        streaming_chunk_first = "{\"errors\":[{\"code\":\"json_validation_error\",\"message\":\"Json document validation error: Either 'prompt_variables' or 'template_variables' must be specified in the request body\",\"more_info\":\"https://cloud.ibm.com/apidocs/watsonx-ai\"}],\"trace\":\"432fec05d5388a16228ff335d05441a1\",\"status_code\":400}"

        stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
          .with(
            body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            }
          ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })

        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(stream_endpoint,
                "POST",
                payload: JSON.parse(payload),
                headers: headers,
                config: sync_config_json[:source][:connection_specification][:config])
          .and_yield(streaming_chunk_first)

        response = Net::HTTPSuccess.new("1.1", "200", "success")
        response.content_type = "application/json"
      end

      it "streams data failed" do
        allow(client).to receive(:get_access_token) do
          client.instance_variable_set(:@access_token, api_key)
        end
        result = client.read(sync_config_stream)
        expect(result).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(result.type).to eq("log")
        expect(result.log.message).to eq("Error: Json document validation error: Either 'prompt_variables' or 'template_variables' must be specified in the request body")
      end
    end

    context "when streaming fails on a chunk" do
      streaming_chunk_first = <<~DATA
        id: 1
        event: message
        data: {"model_id":"ibm/granite-3-8b-instruct","model_version":"1.1.0","created_at":"2025-03-13T23:45:22.678Z","results":[{"generated_text":" (2018)","generated_token_count":8,"input_token_count":1,"stop_reason":"not_finished","seed":0}]}

        id: 10
        event: message
        data: {"model_id":"ibm/granite-3-8b-instruct","model_version":"1.1.0","created_at":"2025-03-13T23:45:25.234Z","results":[{"generated_text":" The goal","generated_token_count":200,"input_token_count":0,"stop_reason":"max_tokens","seed":0}]}
      DATA

      before do
        config = sync_config_json[:source][:connection_specification][:config]

        stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
          .with(
            body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            }
          ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })

        allow(Multiwoven::Integrations::Core::StreamingHttpClient).to receive(:request)
          .with(stream_endpoint,
                "POST",
                payload: JSON.parse(payload.to_json),
                headers: headers,
                config: config)
          .and_yield(streaming_chunk_first)
          .and_raise(StandardError, "Streaming error on chunk 2")
      end

      it "handles streaming errors gracefully" do
        results = []
        allow(client).to receive(:get_access_token) do
          client.instance_variable_set(:@access_token, api_key)
        end
        client.read(sync_config_stream) { |message| results << message }
        expect(results.last).to be_an(Array)
        expect(results.last.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(results.first.first.record.data.dig("results", 0, "generated_text")).to eq(" (2018)")
      end
    end
  end
end
