# frozen_string_literal: true

module Multiwoven
  module Integrations::Protocol
    RSpec.describe ConnectionStatus do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = '{"status": "succeeded", "message": "Connection succeeded"}'
          instance = ConnectionStatus.from_json(json_data)
          expect(instance).to be_a(ConnectionStatus)
          expect(instance.status).to eq("succeeded")
          expect(instance.message).to eq("Connection succeeded")
        end
      end

      describe "#to_multiwoven_message" do
        let(:connection_status) do
          ConnectionStatus.new(
            status: "succeeded",
            message: "Connection succeeded"
          )
        end

        it "converts to a MultiwovenMessage" do
          multiwoven_message = connection_status.to_multiwoven_message

          expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(multiwoven_message.type).to eq("connection_status")
          expect(multiwoven_message.connection_status).to eq(connection_status)
        end
      end
    end

    RSpec.describe ConnectorSpecification do
      json_data = {
        "connection_specification" => { "key" => "value" },
        "stream_type" => "dynamic",
        "supports_normalization" => true,
        "supports_dbt" => true,
        "supported_destination_sync_modes" => ["insert"]
      }

      describe ".from_json" do
        it "creates an instance from JSON" do
          instance = ConnectorSpecification.from_json(json_data.to_json)
          expect(instance).to be_a(ConnectorSpecification)
          expect(instance.connection_specification).to eq(key: "value")
          expect(instance.supports_normalization).to eq(true)
          expect(instance.supports_dbt).to eq(true)
          expect(instance.supported_destination_sync_modes).to eq(["insert"])
          expect(instance.connector_query_type).to eq(nil)
        end

        it "creates an instance from JSON connector_query_type soql" do
          json_data[:connector_query_type] = "soql"
          instance = ConnectorSpecification.from_json(json_data.to_json)
          expect(instance).to be_a(ConnectorSpecification)
          expect(instance.connection_specification).to eq(key: "value")
          expect(instance.supports_normalization).to eq(true)
          expect(instance.supports_dbt).to eq(true)
          expect(instance.supported_destination_sync_modes).to eq(["insert"])
          expect(instance.connector_query_type).to eq("soql")
        end

        it "creates an instance from JSON connector_query_type ai_ml" do
          json_data[:connector_query_type] = "ai_ml"
          json_data[:stream_type] = "user_defined"
          instance = ConnectorSpecification.from_json(json_data.to_json)
          expect(instance).to be_a(ConnectorSpecification)
          expect(instance.connection_specification).to eq(key: "value")
          expect(instance.supports_normalization).to eq(true)
          expect(instance.supported_destination_sync_modes).to eq(["insert"])
          expect(instance.connector_query_type).to eq("ai_ml")
          expect(instance.stream_type).to eq("user_defined")
        end
      end

      describe "#to_multiwoven_message" do
        it "converts to a MultiwovenMessage" do
          connector_spec = described_class.from_json(json_data.to_json)
          multiwoven_message = connector_spec.to_multiwoven_message

          expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(multiwoven_message.type).to eq("connector_spec")
          expect(multiwoven_message.connector_spec).to eq(connector_spec)
        end
      end
    end
    RSpec.describe LogMessage do
      json_data =
        {
          "level" => "info",
          "message" => "Sample log message",
          "stack_trace" => "Sample stack trace"
        }.to_json

      describe ".from_json" do
        it "creates an instance from JSON" do
          log_message = described_class.from_json(json_data)

          expect(log_message).to be_a(described_class)
          expect(log_message.level).to eq("info")
          expect(log_message.message).to eq("Sample log message")
          expect(log_message.stack_trace).to eq("Sample stack trace")
        end
      end

      describe "#to_multiwoven_message" do
        log_message = described_class.from_json(json_data)

        it "converts to a MultiwovenMessage" do
          multiwoven_message = log_message.to_multiwoven_message

          expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(multiwoven_message.type).to eq("log")
          expect(multiwoven_message.log).to eq(log_message)
        end
      end
    end

    RSpec.describe RecordMessage do
      json_data = {
        "data" => { "key" => "value" },
        "emitted_at" => 1_638_449_455_000
      }.to_json

      describe ".from_json" do
        it "creates an instance from JSON" do
          instance = RecordMessage.from_json(json_data)
          expect(instance).to be_a(RecordMessage)
          expect(instance.data).to eq(key: "value")
          expect(instance.emitted_at).to eq(1_638_449_455_000)
        end
      end

      describe "#to_multiwoven_message" do
        it "converts to a MultiwovenMessage" do
          record = described_class.from_json(json_data)
          multiwoven_message = record.to_multiwoven_message

          expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(multiwoven_message.type).to eq("record")
          expect(multiwoven_message.record).to eq(record)
        end
      end
    end

    RSpec.describe Stream do
      describe ".from_json" do
        it "creates an instance from JSON" do
          # TODO: move test json to different module
          json_data = {
            "name": "example_stream", "action": "create",
            "json_schema": { "field1": "type1" },
            "supported_sync_modes": %w[full_refresh incremental],
            "source_defined_cursor": true,
            "default_cursor_field": ["field1"],
            "source_defined_primary_key": [["field1"], ["field2"]],
            "namespace": "exampleNamespace",
            "url": "https://api.example.com/data",
            "request_method": "GET"
          }.to_json
          instance = Stream.from_json(json_data)
          expect(instance).to be_a(Stream)

          expect(instance.name).to eq("example_stream")
          expect(instance.url).to eq("https://api.example.com/data")
          expect(instance.batch_support).to eq(false)
          expect(instance.batch_size).to eq(1)
          expect(instance.supported_sync_modes).to eq(%w[full_refresh incremental])
          expect(instance.source_defined_cursor).to eq(true)

          expect(instance.request_rate_limit).to be_nil
          expect(instance.request_rate_limit_unit).to eq("minute")
          expect(instance.request_rate_concurrency).to be_nil
        end

        it "creates an instance from JSON and batch param check" do
          # TODO: move test json to different module
          json_data = {
            "name": "example_stream", "action": "create",
            "json_schema": { "field1": "type1" },
            "source_defined_cursor": true,
            "default_cursor_field": ["field1"],
            "source_defined_primary_key": [["field1"], ["field2"]],
            "namespace": "exampleNamespace",
            "url": "https://api.example.com/data",
            "request_method": "GET",
            "batch_support": true,
            "batch_size": 10_000,
            "request_rate_limit": 100,
            "request_rate_limit_unit": "minute",
            "request_rate_concurrency": 10
          }.to_json
          instance = Stream.from_json(json_data)
          expect(instance).to be_a(Stream)

          expect(instance.name).to eq("example_stream")
          expect(instance.url).to eq("https://api.example.com/data")
          expect(instance.batch_support).to eq(true)
          expect(instance.batch_size).to eq(10_000)
          expect(instance.supported_sync_modes).to eq(%w[incremental])

          expect(instance.request_rate_limit).to eq(100)
          expect(instance.request_rate_limit_unit).to eq("minute")
          expect(instance.request_rate_concurrency).to eq(10)
          expect(instance.rate_limit_unit_seconds).to eq(60)
        end
      end
    end

    RSpec.describe Catalog do
      json_data = {
        "streams" =>
        [
          { "name" => "example_stream",
            "action" => "create",
            "json_schema" => { "type" => "object" },
            "supported_sync_modes" => ["full_refresh"] }
        ]
      }.to_json

      describe ".from_json" do
        it "creates an instance from JSON" do
          instance = Catalog.from_json(json_data)
          expect(instance).to be_a(Catalog)
          expect(instance.request_rate_limit).to eq(60)
          expect(instance.request_rate_limit_unit).to eq("minute")
          expect(instance.request_rate_concurrency).to eq(10)
          expect(instance.schema_mode).to eql("schema")
          expect(instance.source_defined_cursor).to eql(false)
          expect(instance.default_cursor_field).to eql(nil)
          expect(instance.streams.first).to be_a(Stream)
          expect(instance.streams.first.name).to eq("example_stream")
        end
      end

      describe "with ratelimiting configured" do
        it "creates an instance from JSON" do
          rate_limited_json_data = {
            "request_rate_limit" => 100,
            "request_rate_limit_unit" => "minute",
            "request_rate_concurrency" => 30,
            "streams" =>
            [
              { "name" => "example_stream",
                "action" => "create",
                "json_schema" => { "type" => "object" },
                "supported_sync_modes" => ["full_refresh"] }
            ]
          }.to_json
          instance = Catalog.from_json(rate_limited_json_data)
          expect(instance).to be_a(Catalog)
          expect(instance.request_rate_limit).to eq(100)
          expect(instance.request_rate_limit_unit).to eq("minute")
          expect(instance.request_rate_concurrency).to eq(30)
          expect(instance.streams.first).to be_a(Stream)
          expect(instance.streams.first.name).to eq("example_stream")
        end
      end

      describe "#to_multiwoven_message" do
        it "converts to a MultiwovenMessage" do
          catalog = described_class.from_json(json_data)
          multiwoven_message = catalog.to_multiwoven_message

          expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(multiwoven_message.type).to eq("catalog")
          expect(multiwoven_message.catalog).to eq(catalog)
        end
      end
    end

    RSpec.describe SyncConfig do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = {
            "source": {
              "name": "example_source",
              "type": "source",
              "connection_specification": { "key": "value" }
            },
            "destination": {
              "name": "example_destination",
              "type": "destination",
              "connection_specification": { "key": "value" }
            },
            "model": {
              "name": "example_model",
              "query": "SELECT * FROM customers",
              "query_type": "raw_sql",
              "primary_key": "id"
            },
            "stream": {
              "name": "example_stream", "action": "create",
              "json_schema": { "field1": "type1" },
              "supported_sync_modes": %w[full_refresh incremental],
              "source_defined_cursor": true,
              "default_cursor_field": ["field1"],
              "source_defined_primary_key": [["field1"], ["field2"]],
              "namespace": "exampleNamespace",
              "url": "https://api.example.com/data",
              "request_method": "GET"
            },
            "sync_mode": "full_refresh",
            "destination_sync_mode": "insert",
            "cursor_field": "example_cursor_field",
            "current_cursor_field": "current",
            "offset": "100",
            "limit": "10",
            "sync_id": "sync_id"
          }.to_json

          sync_config = described_class.from_json(json_data)

          expect(sync_config).to be_a(described_class)
          expect(sync_config.source).to be_a(Connector)
          expect(sync_config.source.name).to eq("example_source")
          expect(sync_config.destination).to be_a(Connector)
          expect(sync_config.destination.name).to eq("example_destination")
          expect(sync_config.model).to be_a(Model)
          expect(sync_config.model.name).to eq("example_model")
          expect(sync_config.sync_mode).to eq("full_refresh")
          expect(sync_config.destination_sync_mode).to eq("insert")
          expect(sync_config.cursor_field).to eq("example_cursor_field")
          expect(sync_config.current_cursor_field).to eq("current")
          expect(sync_config.sync_id).to eq("sync_id")
          sync_config.sync_run_id = "sync_run_id"
          expect(sync_config.sync_run_id).to eq("sync_run_id")
          sync_config.limit = "10"
          sync_config.offset = "100"
          expect(sync_config.offset).to eq("100")
          expect(sync_config.limit).to eq("10")
          sync_config.limit = "20"
          sync_config.offset = "200"
          expect(sync_config.offset).to eq("200")
          expect(sync_config.limit).to eq("20")
        end
      end
    end

    RSpec.describe Model do
      context ".from_json" do
        it "creates an instance from JSON" do
          json_data = {
            "name": "example_model",
            "query": "SELECT * FROM customers",
            "query_type": "raw_sql",
            "primary_key": "id"
          }.to_json
          model = Model.from_json(json_data)

          expect(model).to be_a(described_class)
          expect(model.name).to eq("example_model")
          expect(model.query).to eq("SELECT * FROM customers")
          expect(model.query_type).to eq("raw_sql")
          expect(model.primary_key).to eq("id")
        end
      end

      context "query_type validations" do
        it "has a query_type 'sql'" do
          model = Model.new(name: "Test", query: "SELECT * FROM table", query_type: "raw_sql", primary_key: "id")
          expect(ModelQueryType.values).to include(model.query_type)
        end

        it "has a query_type 'soql'" do
          model = Model.new(name: "Test", query: "SELECT * FROM table", query_type: "soql", primary_key: "id")
          expect(ModelQueryType.values).to include(model.query_type)
        end

        it "has a query_type 'dbt'" do
          model = Model.new(name: "Test", query: "SELECT * FROM table", query_type: "dbt", primary_key: "id")
          expect(ModelQueryType.values).to include(model.query_type)
        end

        it "has a query_type 'dbt'" do
          model = Model.new(name: "Test", query: "SELECT * FROM table", query_type: "table_selector", primary_key: "id")
          expect(ModelQueryType.values).to include(model.query_type)
        end

        it "has a query_type 'ai_ml'" do
          model = Model.new(name: "Test", query: "SELECT * FROM table", query_type: "ai_ml", primary_key: "id")
          expect("ai_ml").to include(model.query_type)
        end

        it "has a query_type 'dynamic_sql'" do
          model = Model.new(name: "Test", query: "SELECT * FROM table", query_type: "dynamic_sql", primary_key: "id")
          expect("dynamic_sql").to include(model.query_type)
        end
        it "has a query_type 'unstructured'" do
          model = Model.new(name: "Test", query: "", query_type: "unstructured", primary_key: "id")
          expect("unstructured").to include(model.query_type)
        end
        it "has a query_type 'vector_search'" do
          model = Model.new(name: "Test", query: "SELECT * FROM table", query_type: "vector_search", primary_key: "id")
          expect("vector_search").to include(model.query_type)
        end
      end
    end

    RSpec.describe Connector do
      context ".from_json" do
        json_data = {
          "name": "example_connector",
          "type": "source",
          "connection_specification": { "key": "value" },
          "query_type": "raw_sql"
        }

        it "creates an instance from JSON" do
          connector = Connector.from_json(json_data.to_json)
          expect(connector).to be_a(described_class)
          expect(connector.name).to eq("example_connector")
          expect(connector.type).to eq("source")
          expect(connector.query_type).to eq("raw_sql")
          expect(connector.connection_specification).to eq(key: "value")
        end

        it "creates an instance from JSON connector_query_type ai_ml" do
          json_data[:query_type] = "ai_ml"

          connector = Connector.from_json(json_data.to_json)
          expect(connector).to be_a(described_class)
          expect(connector.name).to eq("example_connector")
          expect(connector.type).to eq("source")
          expect(connector.query_type).to eq("ai_ml")
          expect(connector.connection_specification).to eq(key: "value")
        end
      end
    end

    RSpec.describe Multiwoven::Integrations::Protocol::ControlMessage do
      json_data = {
        "type": "rate_limit",
        "emitted_at": 1_638_449_455_000,
        "meta": { "key": "value" },
        "status": ConnectionStatusType["succeeded"]
      }.to_json

      fullrefresh_json_data = {
        "type": "full_refresh",
        "emitted_at": 1_638_449_455_000,
        "meta": { "key": "value" },
        "status": ConnectionStatusType["succeeded"]
      }.to_json

      describe ".from_json" do
        it "creates an instance from JSON" do
          control_message = described_class.from_json(json_data)

          expect(control_message).to be_a(described_class)
          expect(control_message.type).to eq("rate_limit")
          expect(control_message.emitted_at).to eq(1_638_449_455_000)
          expect(control_message.meta).to eq(key: "value")
        end

        it "creates an full refresh instance from JSON" do
          control_message = described_class.from_json(fullrefresh_json_data)

          expect(control_message).to be_a(described_class)
          expect(control_message.type).to eq("full_refresh")
          expect(control_message.emitted_at).to eq(1_638_449_455_000)
          expect(control_message.meta).to eq(key: "value")
          expect(control_message.status).to eq(ConnectionStatusType["succeeded"])
        end
      end

      describe "#to_multiwoven_message" do
        it "converts to a MultiwovenMessage" do
          control = described_class.from_json(json_data)
          multiwoven_message = control.to_multiwoven_message

          expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(multiwoven_message.type).to eq("control")
          expect(multiwoven_message.control).to eq(control)
        end
      end
    end

    RSpec.describe Multiwoven::Integrations::Protocol::MultiwovenMessage do
      describe ".from_json" do
        let(:json_data) do
          {
            "type": "log",
            "log": { "level": "info", "message": "Sample log message" }
          }.to_json
        end

        it "creates an instance from JSON" do
          multiwoven_message = described_class.from_json(json_data)

          expect(multiwoven_message).to be_a(described_class)
          expect(multiwoven_message.type).to eq("log")
        end
      end
    end
  end

  RSpec.describe Multiwoven::Integrations::Protocol::TrackingMessage do
    describe "#to_multiwoven_message" do
      let(:log_message_data) do
        Multiwoven::Integrations::Protocol::LogMessage.new(
          name: self.class.name,
          level: "info",
          message: { request: "Sample req", response: "Sample req", level: "info" }.to_json
        )
      end
      let(:tracking_message) do
        Multiwoven::Integrations::Protocol::TrackingMessage.new(success: 3, failed: 1, logs: [log_message_data])
      end

      it "converts to a MultiwovenMessage" do
        multiwoven_message = tracking_message.to_multiwoven_message
        expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(multiwoven_message.type).to eq("tracking")
        expect(multiwoven_message.tracking).to eq(tracking_message)
        expect(multiwoven_message.tracking.logs.first).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
        expect(multiwoven_message.tracking.logs.first.level).to eq("info")
        expect(multiwoven_message.tracking.logs.first.message)
          .to eq("{\"request\":\"Sample req\",\"response\":\"Sample req\",\"level\":\"info\"}")
      end
    end
  end
end
