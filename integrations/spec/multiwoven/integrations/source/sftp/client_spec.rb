# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Sftp::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:mock_connection) { double("MockedConnection") }
  let(:connection_config) do
    {
      file_path: "/multiwoven",
      file_name: "test",
      format_type: "csv"
    }.with_indifferent_access
  end
  let(:sync_config) do
    { source: {
        name: "Sftp",
        type: "source",
        connection_specification: connection_config
      },
      destination: {
        name: "DestinationName",
        type: "destination",
        connection_specification: {
          api_key: "Test"
        }
      },
      model: {
        name: "ExampleModel",
        query: "SELECT col1, col2, col3 FROM /multiwoven/test.csv",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "sftp",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: {}
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:mock_sftp_client) do
    instance_double("Net::SFTP::Session").tap do |sftp|
      allow(sftp).to receive(:stat!)
      allow(sftp).to receive(:download!)
    end
  end

  let(:mock_columns) do
    [
      instance_double("DuckDB::Column", name: "col1"),
      instance_double("DuckDB::Column", name: "col2")
    ]
  end

  let(:mock_duckdb_result) do
    instance_double("DuckDB::Result").tap do |result|
      allow(result).to receive(:columns).and_return(mock_columns)
      allow(result).to receive(:map).and_return([{ "col1" => "1", "col2" => "First" }])
      allow(result).to receive(:columns).and_return([
                                                      instance_double("DuckDB::Column", name: "col1"),
                                                      instance_double("DuckDB::Column", name: "col2")
                                                    ])
    end
  end

  let(:tempfile) { instance_double("Tempfile", path: "/mock/path/to/file.csv") }
  let(:mock_duckdb_connection) { instance_double("DuckDB::Connection") }

  before do
    allow(Net::SFTP).to receive(:start).and_return(mock_sftp_client) # Setup the mock SFTP client
    allow(Tempfile).to receive(:new).and_return(tempfile)
    allow(tempfile).to receive(:close!)
    allow(DuckDB::Database).to receive(:open).and_return(instance_double("DuckDB::Database", connect: mock_duckdb_connection))
    allow(mock_duckdb_connection).to receive(:execute)
    allow(mock_sftp_client).to receive(:stat!).and_return(instance_double("Net::SFTP::Attributes"))
    allow(mock_sftp_client).to receive(:download!)
  end

  describe "#check_connection" do
    it "successfully checks connection" do
      response = client.check_connection(connection_config)
      expect(response.connection_status.status).to eq("succeeded")
    end

    it "handles connection failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError.new("connection failed"))
      response = client.check_connection(connection_config)
      expect(response.connection_status.status).to eq("failed")
      expect(response.connection_status.message).to eq("connection failed")
    end
  end

  describe "#discover" do
    it "returns a catalog" do
      allow(mock_duckdb_connection).to receive(:query).and_return(mock_duckdb_result)
      message = client.discover(connection_config)
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("/multiwoven/test.csv")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "col1" => { "type" => %w[string null] } })
    end

    it "discover schema failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "SFTP:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      client.discover(sync_config[:source][:connection_specification])
    end
  end

  describe "#read" do
    it "reads records successfully" do
      query = "SELECT col1, col2, col3 FROM read_csv_auto('/mock/path/to/file.csv')"
      allow(mock_duckdb_connection).to receive(:query).with(query).and_return(mock_duckdb_result)
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      message = client.read(s_config)
      expect(message).to be_an(Array)
      expect(message).not_to be_empty
      expect(message.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully using SQL with multiple FROMs" do
      query = "SELECT * FROM (SELECT col1, col2, col3 FROM read_csv_auto('/mock/path/to/file.csv')) AS subquery ORDER BY RANDOM()"
      allow(mock_duckdb_connection).to receive(:query).with(query).and_return(mock_duckdb_result)
      sync_config["model"]["query"] = "SELECT * FROM (#{sync_config["model"]["query"]}) AS subquery ORDER BY RANDOM()"
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      message = client.read(s_config)
      expect(message).to be_an(Array)
      expect(message).not_to be_empty
      expect(message.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully with limit" do
      allow(mock_duckdb_connection).to receive(:query).and_return(mock_duckdb_result)
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      message = client.read(s_config)
      expect(message).to be_an(Array)
      expect(message).not_to be_empty
      expect(message.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "read records failure" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.sync_run_id = "2"
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError),
        hash_including(
          context: "SFTP:READ:EXCEPTION",
          sync_run_id: "2",
          type: "error"
        )
      )
      client.read(s_config)
    end
  end

  describe "#meta_data" do
    # change this to rollout validation for all connector rolling out
    it "client class_name and meta name is same" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end

  describe "method definition" do
    it "defines a private #query method" do
      expect(described_class.private_instance_methods).to include(:query)
    end
  end
end
