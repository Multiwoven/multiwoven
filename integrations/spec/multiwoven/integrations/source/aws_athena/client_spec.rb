# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::AwsAthena::Client do
  let(:client) { Multiwoven::Integrations::Source::AwsAthena::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "AWS Athena",
        "type": "source",
        "connection_specification": {
          "access_key": ENV["ATHENA_ACCESS"],
          "secret_access_key": ENV["ATHENA_SECRET"],
          "region": "us-east-2",
          "workgroup": "your_workgroup",
          "catalog": "AwsDatacatalog",
          "schema": "your_database",
          "output_location": "s3://s3bucket-ai2-test"
        }
      },
      "destination": {
        "name": "Sample Destination Connector",
        "type": "destination",
        "connection_specification": {
          "example_destination_key": "example_destination_value"
        }
      },
      "model": {
        "name": "Anthena Account",
        "query": "SELECT column1, column2 FROM your_table",
        "query_type": "raw_sql",
        "primary_key": "id"
      },
      "stream": {
        "name": "example_stream",
        "action": "create",
        "json_schema": { "field1": "type1" },
        "supported_sync_modes": %w[full_refresh incremental],
        "source_defined_cursor": true,
        "default_cursor_field": ["field1"],
        "source_defined_primary_key": [["field1"], ["field2"]],
        "namespace": "exampleNamespace",
        "url": "https://api.example.com/data",
        "method": "GET"
      },
      "sync_mode": "full_refresh",
      "cursor_field": "timestamp",
      "destination_sync_mode": "upsert",
      "sync_id": "1"
    }
  end

  let(:athena_client) { instance_double(Aws::Athena::Client) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AwsAthena::Client).to receive(:create_connection).and_return(athena_client)
        expect(athena_client).to receive(:list_work_groups)
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow_any_instance_of(Multiwoven::Integrations::Source::AwsAthena::Client).to receive(:create_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  # read and #discover tests for AWS Athena
  describe "#read" do
    it "reads records successfully" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      allow(client).to receive(:create_connection).and_return(athena_client)
      allow(athena_client).to receive(:start_query_execution).and_return(query_execution_id: "abc123")
      allow(athena_client).to receive(:get_query_execution).and_return(
        Aws::Athena::Types::GetQueryExecutionOutput.new(
          query_execution: Aws::Athena::Types::QueryExecution.new(
            query_execution_id: "abc123",
            query: "SELECT column1, column2 FROM your_table",
            statement_type: "DML",
            result_configuration: Aws::Athena::Types::ResultConfiguration.new(output_location: "s3://s3bucket-ai2-test/abc123.csv"),
            query_execution_context: Aws::Athena::Types::QueryExecutionContext.new(database: "your_database"),
            status: Aws::Athena::Types::QueryExecutionStatus.new(state: "SUCCEEDED"),
            work_group: "your_workgroup",
            substatement_type: "SELECT"
          )
        )
      )
      allow(athena_client).to receive(:get_query_results).and_return(
        Aws::Athena::Types::GetQueryResultsOutput.new(
          result_set: Aws::Athena::Types::ResultSet.new(
            rows: [
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: "column1"),
                  Aws::Athena::Types::Datum.new(var_char_value: "column2")
                ]
              ),
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: nil),
                  Aws::Athena::Types::Datum.new(var_char_value: nil)
                ]
              )
            ],
            result_set_metadata: Aws::Athena::Types::ResultSetMetadata.new(
              column_info: [
                Aws::Athena::Types::ColumnInfo.new(name: "column1", label: "column1", type: "varchar"),
                Aws::Athena::Types::ColumnInfo.new(name: "column2", label: "column2", type: "varchar")
              ]
            )
          )
        )
      )
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "reads records successfully for batched_query" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.limit = 100
      s_config.offset = 1
      allow(client).to receive(:create_connection).and_return(athena_client)
      batched_query = client.send(:batched_query, s_config.model.query, s_config.limit, s_config.offset)
      allow(athena_client).to receive(:start_query_execution).and_return(query_execution_id: "abc123")
      allow(athena_client).to receive(:get_query_execution).and_return(
        Aws::Athena::Types::GetQueryExecutionOutput.new(
          query_execution: Aws::Athena::Types::QueryExecution.new(
            query_execution_id: "abc123",
            query: "SELECT column1, column2 FROM your_table",
            statement_type: "DML",
            result_configuration: Aws::Athena::Types::ResultConfiguration.new(
              output_location: "s3://s3bucket-ai2-test/abc123.csv"
            ),
            query_execution_context: Aws::Athena::Types::QueryExecutionContext.new(
              database: "your_database"
            ),
            status: Aws::Athena::Types::QueryExecutionStatus.new(
              state: "SUCCEEDED"
            ),
            work_group: "your_workgroup",
            substatement_type: "SELECT"
          )
        )
      )
      allow(athena_client).to receive(:get_query_results).and_return(
        Aws::Athena::Types::GetQueryResultsOutput.new(
          result_set: Aws::Athena::Types::ResultSet.new(
            rows: [
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: "column1"),
                  Aws::Athena::Types::Datum.new(var_char_value: "column2")
                ]
              ),
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: nil),
                  Aws::Athena::Types::Datum.new(var_char_value: nil)
                ]
              )
            ],
            result_set_metadata: Aws::Athena::Types::ResultSetMetadata.new(
              column_info: [
                Aws::Athena::Types::ColumnInfo.new(name: "column1", label: "column1", type: "varchar"),
                Aws::Athena::Types::ColumnInfo.new(name: "column2", label: "column2", type: "varchar")
              ]
            )
          )
        )
      )
      allow(client).to receive(batched_query).and_return("SELECT column1, column2 FROM your_table LIMIT 100 OFFSET 1")
      records = client.read(s_config)
      expect(records).to be_an(Array)
      expect(records).not_to be_empty
      expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
    end

    it "read records failure" do
      s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
      s_config.sync_run_id = "2"
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "AWS:ATHENA:READ:EXCEPTION",
          type: "error",
          sync_id: "1",
          sync_run_id: "2"
        }
      )
      client.read(s_config)
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      # Mocking Athena client and query behavior
      allow(Aws::Athena::Client).to receive(:new).and_return(athena_client)
      discovery_query = "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = sync_config[:source][:connection_specification][:schema} ORDER BY table_name, ordinal_position;"
      allow(athena_client).to receive(:start_query_execution).and_return(query_execution_id: "abc123")
      allow(athena_client).to receive(:get_query_execution).and_return(
        Aws::Athena::Types::GetQueryExecutionOutput.new(
          query_execution: Aws::Athena::Types::QueryExecution.new(
            query_execution_id: "abc123",
            query: discovery_query,
            statement_type: "DML",
            result_configuration: Aws::Athena::Types::ResultConfiguration.new(
              output_location: "s3://s3bucket-ai2-test/abc123.csv"
            ),
            query_execution_context: Aws::Athena::Types::QueryExecutionContext.new(
              database: "your_database"
            ),
            status: Aws::Athena::Types::QueryExecutionStatus.new(
              state: "SUCCEEDED"
            ),
            work_group: "your_workgroup",
            substatement_type: "SELECT"
          )
        )
      )
      allow(athena_client).to receive(:get_query_results).and_return(
        Aws::Athena::Types::GetQueryResultsOutput.new(
          result_set: Aws::Athena::Types::ResultSet.new(
            rows: [
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: "table_name"),
                  Aws::Athena::Types::Datum.new(var_char_value: "column_name"),
                  Aws::Athena::Types::Datum.new(var_char_value: "data_type"),
                  Aws::Athena::Types::Datum.new(var_char_value: "is_nullable")
                ]
              ),
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: "table1"),
                  Aws::Athena::Types::Datum.new(var_char_value: "table_name"),
                  Aws::Athena::Types::Datum.new(var_char_value: "varchar(255)"),
                  Aws::Athena::Types::Datum.new(var_char_value: "YES")
                ]
              ),
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: "table1"),
                  Aws::Athena::Types::Datum.new(var_char_value: "column_name"),
                  Aws::Athena::Types::Datum.new(var_char_value: "varchar(255)"),
                  Aws::Athena::Types::Datum.new(var_char_value: "YES")
                ]
              ),
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: "table1"),
                  Aws::Athena::Types::Datum.new(var_char_value: "is_nullable"),
                  Aws::Athena::Types::Datum.new(var_char_value: "varchar(255)"),
                  Aws::Athena::Types::Datum.new(var_char_value: "YES")
                ]
              ),
              Aws::Athena::Types::Row.new(
                data: [
                  Aws::Athena::Types::Datum.new(var_char_value: "table1"),
                  Aws::Athena::Types::Datum.new(var_char_value: "is_nullable"),
                  Aws::Athena::Types::Datum.new(var_char_value: "varchar(255)"),
                  Aws::Athena::Types::Datum.new(var_char_value: "YES")
                ]
              )
            ],
            result_set_metadata: Aws::Athena::Types::ResultSetMetadata.new(
              column_info: [
                Aws::Athena::Types::ColumnInfo.new(name: "table_name", label: "table_name", type: "varchar"),
                Aws::Athena::Types::ColumnInfo.new(name: "column_name", label: "column_name", type: "varchar"),
                Aws::Athena::Types::ColumnInfo.new(name: "data_type", label: "data_type", type: "varchar"),
                Aws::Athena::Types::ColumnInfo.new(name: "is_nullable", label: "is_nullable", type: "varchar")
              ]
            )
          )
        )
      )
      message = client.discover(sync_config[:source][:connection_specification])
      expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
      first_stream = message.catalog.streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("table_name")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "column_name" => { "type" => "string" } })
    end

    it "discover schema failure" do
      allow(client).to receive(:create_connection).and_raise(StandardError, "test error")
      expect(client).to receive(:handle_exception).with(
        an_instance_of(StandardError), {
          context: "AWS:ATHENA:DISCOVER:EXCEPTION",
          type: "error"
        }
      )
      client.discover(sync_config[:source][:connection_specification])
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
