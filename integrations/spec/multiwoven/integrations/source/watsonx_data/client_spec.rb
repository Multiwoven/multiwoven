# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::WatsonxData::Client do
  let(:client) { Multiwoven::Integrations::Source::WatsonxData::Client.new }
  let(:api_key) { "test_api_key" }
  let(:sync_config_json) do
    {
      source: {
        name: "WatsonX Data",
        type: "source",
        connection_specification: {
          api_key: api_key,
          region: "us-south",
          engine: "presto",
          engine_id: "presto000",
          auth_instance_id: "crn:v1:bluemix:public:lakehouse:us-south:uuid::",
          database: "sample_database",
          schema: "public",
          config: {
            timeout: 25
          }
        }
      },
      destination: {
        name: "Sample Destination Connector",
        type: "destination",
        connection_specification: {
          private_api_key: "your_key"
        }
      },
      model: {
        name: "Sample Model",
        query: "SELECT * FROM table",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "examle_stream",
        request_method: "POST",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: {}
      },
      sync_mode: "full_refresh",
      destination_sync_mode: "upsert"
    }
  end
  let(:headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{api_key}",
      "AuthInstanceId" => "crn:v1:bluemix:public:lakehouse:us-south:uuid::",
      "Content-Type" => "application/json"
    }
  end
  let(:query_endpoint) { "https://us-south.lakehouse.cloud.ibm.com/lakehouse/api/v2/queries/execute/#{sync_config_json[:source][:connection_specification][:engine_id]}" }

  before do
    stub_request(:post, "https://iam.cloud.ibm.com/identity/token")
      .with(
        body: { "apikey" => api_key, "grant_type" => "urn:ibm:params:oauth:grant-type:apikey" },
        headers: {
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      ).to_return(status: 200, body: { "access_token" => api_key }.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "#check_connection" do
    let(:payload) do
      {
        "catalog_name": "sample_database",
        "schema_name": "public",
        "sql_string": "show catalogs"
      }
    end
    context "when the connection is succesful" do
      let(:response_body) do
        {
          "response" =>
            {
              "result" => [{ "catalog": "sample_database" }]
            }
        }.to_json
      end
      before do
        stub_response = Net::HTTPSuccess.new("1.1", "200", "OK")
        stub_response.content_type = "application/json"
        allow(stub_response).to receive(:body).and_return(response_body)

        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(query_endpoint, "POST", payload: payload, headers: headers, config: config)
          .and_return(stub_response)
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
          "response": "failed"
        }
      end
      before do
        stub_response = Net::HTTPSuccess.new("1.1", "400", "Unauthorized")
        stub_response.content_type = "application/json"
        allow(stub_response).to receive(:body).and_return(response_body)

        config = sync_config_json[:source][:connection_specification][:config]
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(query_endpoint, "POST", payload: payload, headers: headers, config: config)
      end

      it "returns a failed connection status with an error message" do
        response = client.check_connection(sync_config_json[:source][:connection_specification])

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    let(:response_body) do
      {
        "response" => {
          "result" => [
            {
              "table_name": "table",
              "column_name": "column",
              "data_type": "varchar",
              "is_nullable": "YES"
            }
          ]
        }
      }.to_json
    end
    let(:payload) do
      {
        "catalog_name": "sample_database",
        "schema_name": "public",
        "sql_string": "SELECT table_name, column_name,
                  data_type,
                  is_nullable
                  FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_catalog = 'sample_database'
                  ORDER BY table_name, ordinal_position"
      }
    end
    before do
      stub_response = Net::HTTPSuccess.new("1.1", "200", "Ok")
      stub_response.content_type = "application/json"
      allow(stub_response).to receive(:body).and_return(response_body)

      config = sync_config_json[:source][:connection_specification][:config]
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(query_endpoint, "POST", payload: payload, headers: headers, config: config)
        .and_return(stub_response)
    end

    it "successfully returns the catalog message" do
      message = client.discover(sync_config_json[:source][:connection_specification])
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
    end

    it "handle exception during discovery" do
      message = client.discover(nil)
      catalog = message.catalog
      expect(catalog).to be(nil)
    end
  end

  describe "#read" do
    let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
    let(:response_body) do
      {
        "response" =>
        {
          "result" =>
          [
            {
              "id": "1",
              "name": "name"
            }
          ]
        }
      }.to_json
    end
    let(:payload) do
      {
        "catalog_name": "sample_database",
        "schema_name": "public",
        "sql_string": "SELECT * FROM table"
      }
    end
    let(:error_instance) { StandardError.new("WatsonX Data API error") }
    let(:batched_query) do
      <<~SQL
        SELECT * FROM (
          SELECT *, ROW_NUMBER() OVER () as rownum FROM ( SELECT * FROM table ) subquery
        ) t
        WHERE rownum > 1
        LIMIT 100
      SQL
    end
    before do
      stub_response = Net::HTTPSuccess.new("1.1", "200", "Ok")
      stub_response.content_type = "application/json"
      allow(stub_response).to receive(:body).and_return(response_body)

      config = sync_config_json[:source][:connection_specification][:config]
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(query_endpoint, "POST", payload: payload, headers: headers, config: config)
        .and_return(stub_response)
    end

    it "reads records successfully" do
      records = client.read(sync_config)
      expect(records).to be_an(Array)
      expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
      expect(records.first.record.data).to eq(JSON.parse(response_body)["response"]["result"][0])
    end

    it "reads records successfully for batched_query" do
      sync_config.limit = 100
      sync_config.offset = 1
      payload[:sql_string] = batched_query

      stub_response = Net::HTTPSuccess.new("1.1", "200", "Ok")
      stub_response.content_type = "application/json"
      allow(stub_response).to receive(:body).and_return(response_body)

      config = sync_config_json[:source][:connection_specification][:config]
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
        .with(query_endpoint, "POST", payload: payload, headers: headers, config: config)
        .and_return(stub_response)

      records = client.read(sync_config)
      expect(records).to be_an(Array)
      expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
      expect(records.first.record.data).to eq(JSON.parse(response_body)["response"]["result"][0])
    end

    it "handles exceptions during reading" do
      allow(client).to receive(:query).and_raise(error_instance)
      expect(client).to receive(:handle_exception).with(
        error_instance,
        {
          context: "WATSONX DATA:READ:EXCEPTION",
          type: "error"
        }
      )
      client.read(sync_config)
    end

    it "returns modified query with rownum" do
      limit = 100
      offset = 1
      query = client.send(:batched_query_for_presto, payload[:sql_string], limit, offset)

      expect(query).to eq(batched_query)
    end
  end
end
