# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::MicrosoftExcel::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      token: "test"
    }
  end
  let(:sync_config_json) do
    {
      source: {
        name: "Sample Source Connector",
        type: "source",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Databricks",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT col1, col2, col3 FROM test_table_1",
        query_type: "raw_sql",
        primary_key: "col1"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "test_table.xlsx",
        action: "create",
        json_schema: {},
        supported_sync_modes: %w[incremental],
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1
      }
    }
  end

  let(:response_body) { { "id" => "DRIVE1" }.to_json }
  let(:successful_update_response_body) { { "values" => [["400", "4.4", "Fourth"]] }.to_json }
  let(:failed_update_response_body) { { "values" => [["400", "4.4", "Fourth"]] }.to_json }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        stub_request(:get, "https://graph.microsoft.com/v1.0/me")
          .to_return(status: 200, body: response_body, headers: {})

        allow(client).to receive(:create_connection).and_return("DRIVE1")

        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config_json[:destination][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      stub_request(:get, "https://graph.microsoft.com/v1.0/me")
        .to_return(status: 200, body: response_body, headers: {})
      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/DRIVE1/root/children")
        .to_return(
          status: 200,
          body: {
            "value" => [
              { "id" => "file1_id", "name" => "test_file.xlsx" }
            ]
          }.to_json,
          headers: {}
        )
      allow(client).to receive(:get_all_sheets).and_return([
                                                             { "name" => "Sheet1" }
                                                           ])
      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/DRIVE1/items/file1_id/workbook/worksheets/Sheet1/"\
      "range(address='A1:Z1')/usedRange?$select=values")
        .to_return(
          status: 200,
          body: {
            "values" => [%w[col1 col2 col3]]
          }.to_json,
          headers: {}
        )

      message = client.discover(connection_config)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.streams.first.request_rate_limit).to eql(6000)
      expect(catalog.streams.first.request_rate_limit_unit).to eql("minute")
      expect(catalog.streams.first.request_rate_concurrency).to eql(10)
      expect(catalog.streams.count).to eql(1)
      expect(catalog.streams[0].supported_sync_modes).to eql(%w[incremental])
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      it "increments the success count" do
        stub_request(:get, "https://graph.microsoft.com/v1.0/me")
          .to_return(status: 200, body: response_body, headers: {})

        stub_request(:get, "https://graph.microsoft.com/v1.0/drives/DRIVE1/root/children")
          .to_return(
            status: 200,
            body: {
              "value" => [
                { "id" => "file1_id", "name" => "test_table.xlsx" }
              ]
            }.to_json,
            headers: {}
          )

        stub_request(:get, "https://graph.microsoft.com/v1.0/drives/DRIVE1/items/file1_id/workbook/worksheets/sheet/"\
        "tables?$select=name")
          .to_return(
            status: 200,
            body: {
              "value" => [
                { "name" => "Table1" }
              ]
            }.to_json,
            headers: {}
          )

        stub_request(:post, "https://graph.microsoft.com/v1.0/drives/DRIVE1/items/file1_id/workbook/worksheets/"\
        "test_table.xlsx/tables/Table1/rows")
          .to_return(status: 201, body: successful_update_response_body, headers: {})

        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        records = [{ "Col1" => 400, "Col2" => 4.4, "Col3" => "Fourth" }]

        message = client.write(sync_config, records)
        tracker = message.tracking

        expect(tracker.success).to eq(records.count)
        expect(tracker.failed).to eq(0)
        log_message = message.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end

    context "when the write operation fails" do
      it "increments the failure count" do
        stub_request(:get, "https://graph.microsoft.com/v1.0/me")
          .to_return(status: 200, body: response_body, headers: {})

        stub_request(:get, "https://graph.microsoft.com/v1.0/drives/DRIVE1/root/children")
          .to_return(
            status: 200,
            body: {
              "value" => [
                { "id" => "file1_id", "name" => "test_table.xlsx" }
              ]
            }.to_json,
            headers: {}
          )

        stub_request(:get, "https://graph.microsoft.com/v1.0/drives/DRIVE1/items/file1_id/workbook/worksheets/sheet/"\
         "tables?$select=name")
          .to_return(
            status: 200,
            body: {
              "value" => [
                { "name" => "Table1" }
              ]
            }.to_json,
            headers: {}
          )

        stub_request(:post,
                     "https://graph.microsoft.com/v1.0/drives/DRIVE1/items/file1_id/workbook/worksheets/"\
                     "test_table.xlsx/tables/Table1/rows")
          .to_return(status: 400, body: failed_update_response_body, headers: {})

        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
        records = [{ "Col1" => 400, "Col2" => 4.4, "Col3" => "Fourth" }]

        message = client.write(sync_config, records)
        tracker = message.tracking
        expect(tracker.failed).to eq(records.count)
        expect(tracker.success).to eq(0)
        log_message = message.tracking.logs.first
        expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(log_message.level).to eql("info")

        expect(log_message.message).to include("request")
        expect(log_message.message).to include("response")
      end
    end
  end

  describe "#meta_data" do
    # change this to rollout validation for all connector rolling out
    it "client class_name and meta name is same" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end
end
