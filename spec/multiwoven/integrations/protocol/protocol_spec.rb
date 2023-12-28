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
      }.to_json

      describe ".from_json" do
        it "creates an instance from JSON" do
          instance = ConnectorSpecification.from_json(json_data)
          expect(instance).to be_a(ConnectorSpecification)
          expect(instance.connection_specification).to eq(key: "value")
          expect(instance.supports_normalization).to eq(true)
          expect(instance.supports_dbt).to eq(true)
          expect(instance.supported_destination_sync_modes).to eq(["insert"])
        end
      end

      describe "#to_multiwoven_message" do
        it "converts to a MultiwovenMessage" do
          connector_spec = described_class.from_json(json_data)
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
          expect(instance.supported_sync_modes).to eq(%w[full_refresh incremental])
        end
      end
    end

    RSpec.describe Catalog do
      json_data = {
        "streams" =>
        [{ "name" => "example_stream",
           "action" => "create",
           "json_schema" => { "type" => "object" },
           "supported_sync_modes" => ["full_refresh"] }]
      }.to_json

      describe ".from_json" do
        it "creates an instance from JSON" do
          instance = Catalog.from_json(json_data)
          expect(instance).to be_a(Catalog)
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
            "destination_sync_mode": "insert"
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
        end
      end
    end

    RSpec.describe Model do
      describe ".from_json" do
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
    end

    RSpec.describe Connector do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data =  {
            "name": "example_connector",
            "type": "source",
            "connection_specification": { "key": "value" }
          }.to_json

          connector = Connector.from_json(json_data)
          expect(connector).to be_a(described_class)
          expect(connector.name).to eq("example_connector")
          expect(connector.type).to eq("source")
          expect(connector.connection_specification).to eq(key: "value")
        end
      end
    end

    RSpec.describe Multiwoven::Integrations::Protocol::ControlMessage do
      json_data = {
        "type": "rate_limit",
        "emitted_at": 1_638_449_455_000,
        "meta": { "key": "value" }
      }.to_json

      describe ".from_json" do
        it "creates an instance from JSON" do
          control_message = described_class.from_json(json_data)

          expect(control_message).to be_a(described_class)
          expect(control_message.type).to eq("rate_limit")
          expect(control_message.emitted_at).to eq(1_638_449_455_000)
          expect(control_message.meta).to eq(key: "value")
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
      let(:tracking_message) do
        Multiwoven::Integrations::Protocol::TrackingMessage.new(success: 3, failed: 1)
      end

      it "converts to a MultiwovenMessage" do
        multiwoven_message = tracking_message.to_multiwoven_message

        expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(multiwoven_message.type).to eq("tracking")
        expect(multiwoven_message.tracking).to eq(tracking_message)
      end
    end
  end
end
