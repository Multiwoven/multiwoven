# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Weaviate::Client do
  let(:client) { described_class.new }
  let(:rails_logger) { instance_double(Logger, info: nil, error: nil, warn: nil, debug: nil) }

  before do
    stub_const("Rails", Class.new)
    allow(Rails).to receive(:logger).and_return(rails_logger)
  end

  let(:connection_config) do
    {
      api_url: "my-instance.weaviate.cloud",
      api_key: "test-key"
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
        name: "Weaviate",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM users",
        query_type: "raw_sql",
        primary_key: "id"
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      stream: {
        name: "UserProfile",
        action: "create",
        supported_sync_modes: %w[incremental full_refresh],
        json_schema: {
          type: "object",
          properties: {
            name: { type: "string" }
          }
        }
      }
    }
  end

  let(:schema_resource) { instance_double("WeaviateSchemaResource") }
  let(:objects_resource) { instance_double("WeaviateObjectsResource") }
  let(:weaviate_client) { instance_double(::Weaviate::Client, schema: schema_resource, objects: objects_resource) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(schema_resource).to receive(:list).and_return({ "classes" => [] })

        message = client.check_connection(connection_config)
        result = message.connection_status

        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:build_client).and_raise(StandardError.new("Connection failed"))

        message = client.check_connection(connection_config)
        result = message.connection_status

        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    let(:schema_with_classes) do
      {
        "classes" => [
          {
            "class" => "UserProfile",
            "properties" => [
              { "name" => "name", "dataType" => ["text"] },
              { "name" => "age", "dataType" => ["int"] }
            ]
          }
        ]
      }
    end

    context "when schema discovery succeeds" do
      it "returns a catalog with streams" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(schema_resource).to receive(:list).and_return(schema_with_classes)

        message = client.discover(connection_config)

        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
        first_stream = message.catalog.streams.first
        expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(first_stream.name).to eq("UserProfile")
        expect(first_stream.json_schema["properties"]["vector"]["type"]).to eq("vector")
        expect(first_stream.json_schema["properties"]["properties"]["properties"]["name"]["type"]).to eq("string")
        expect(first_stream.json_schema["properties"]["properties"]["properties"]["age"]["type"]).to eq("integer")
      end

      it "excludes the vector property from stream properties" do
        schema_with_vector = {
          "classes" => [
            {
              "class" => "UserProfile",
              "properties" => [
                { "name" => "vector", "dataType" => ["number[]"] },
                { "name" => "name", "dataType" => ["text"] }
              ]
            }
          ]
        }
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(schema_resource).to receive(:list).and_return(schema_with_vector)

        message = client.discover(connection_config)
        props = message.catalog.streams.first.json_schema["properties"]["properties"]["properties"]

        expect(props.keys).not_to include("vector")
        expect(props.keys).to include("name")
      end

      it "maps Weaviate types to JSON schema types correctly" do
        schema_with_types = {
          "classes" => [
            {
              "class" => "Product",
              "properties" => [
                { "name" => "label",     "dataType" => ["text"] },
                { "name" => "count",     "dataType" => ["int"] },
                { "name" => "price",     "dataType" => ["number"] },
                { "name" => "active",    "dataType" => ["boolean"] },
                { "name" => "created",   "dataType" => ["date"] }
              ]
            }
          ]
        }
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(schema_resource).to receive(:list).and_return(schema_with_types)

        props = client.discover(connection_config).catalog.streams.first
                      .json_schema["properties"]["properties"]["properties"]

        expect(props["label"]["type"]).to eq("string")
        expect(props["count"]["type"]).to eq("integer")
        expect(props["price"]["type"]).to eq("number")
        expect(props["active"]["type"]).to eq("boolean")
        expect(props["created"]["type"]).to eq("string")
      end
    end

    context "when schema has no classes" do
      it "returns a catalog with empty streams" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(schema_resource).to receive(:list).and_return({ "classes" => [] })

        message = client.discover(connection_config)
        expect(message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(message.catalog.streams).to be_empty
      end
    end

    context "when schema classes are nil" do
      it "returns a catalog with empty streams" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(schema_resource).to receive(:list).and_return({ "classes" => nil })

        message = client.discover(connection_config)
        expect(message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(message.catalog.streams).to be_empty
      end
    end

    context "when an exception occurs" do
      it "returns a log message with discover context" do
        allow(client).to receive(:build_client).and_raise(StandardError.new("Discovery failed"))

        message = client.discover(connection_config)
        expect(message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(message.log.name).to eq("WEAVIATE:DISCOVER:EXCEPTION")
        expect(message.log.message).to eq("Discovery failed")
      end
    end
  end

  describe "#write" do
    let(:records) do
      [
        { "id" => "1", "vector" => [0.1, 0.2], "properties" => { "name" => "Alice", "age" => "30" } },
        { "id" => "2", "vector" => [0.3, 0.4], "properties" => { "name" => "Bob",   "age" => "25" } }
      ]
    end

    let(:sync_config_with_schema) do
      Multiwoven::Integrations::Protocol::SyncConfig.from_json(
        sync_config_json.merge(
          stream: {
            name: "UserProfile",
            action: "create",
            supported_sync_modes: %w[incremental],
            json_schema: {
              type: "object",
              properties: {
                id: { type: "string" },
                vector: { type: "vector" },
                properties: {
                  type: "object",
                  properties: {
                    name: { type: "string" },
                    age: { type: "integer" }
                  }
                }
              }
            }
          }
        ).to_json
      )
    end

    let(:sync_config) do
      Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
    end

    context "when write succeeds for all records" do
      it "returns tracking with all successes" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(objects_resource).to receive(:batch_create).and_return(
          [
            { "result" => { "status" => "SUCCESS" } },
            { "result" => { "status" => "SUCCESS" } }
          ]
        )

        message = client.write(sync_config_with_schema, records)
        tracking = message.tracking

        expect(tracking.success).to eq(2)
        expect(tracking.failed).to eq(0)
      end
    end

    context "when write has partial failures" do
      it "returns tracking with success and failure counts" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(objects_resource).to receive(:batch_create).and_return(
          [
            { "result" => { "status" => "SUCCESS" } },
            { "result" => { "status" => "FAILED" } }
          ]
        )

        message = client.write(sync_config_with_schema, records)
        tracking = message.tracking

        expect(tracking.success).to eq(1)
        expect(tracking.failed).to eq(1)
        expect(tracking.logs.map(&:level)).to include("info", "error")
      end
    end

    context "when write raises an exception" do
      it "returns a log message with write context" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(objects_resource).to receive(:batch_create).and_raise(StandardError.new("Batch failed"))

        message = client.write(sync_config_with_schema, records)

        expect(message).to be_an(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(message.log.name).to eq("WEAVIATE:RECORD:WRITE:EXCEPTION")
        expect(message.log.message).to eq("Batch failed")
      end
    end

    context "when record id is present" do
      it "generates a deterministic UUID from the id" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        expected_uuid = client.send(:generate_uuid, "1")
        captured_objects = nil
        allow(objects_resource).to receive(:batch_create) do |args|
          captured_objects = args[:objects]
          [{ "result" => { "status" => "SUCCESS" } }]
        end

        client.write(sync_config_with_schema, [records.first])

        expect(captured_objects.first[:id]).to eq(expected_uuid)
      end
    end

    context "when record id is absent" do
      it "falls back to a random UUID" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        record_without_id = { "vector" => [0.1], "properties" => { "name" => "Ghost" } }
        captured_objects = nil
        allow(objects_resource).to receive(:batch_create) do |args|
          captured_objects = args[:objects]
          [{ "result" => { "status" => "SUCCESS" } }]
        end

        client.write(sync_config_with_schema, [record_without_id])

        expect(captured_objects.first[:id]).to match(/\A[0-9a-f-]{36}\z/)
      end
    end

    context "when properties contain numeric strings" do
      it "coerces integer strings to integers before sending to Weaviate" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        captured_objects = nil
        allow(objects_resource).to receive(:batch_create) do |args|
          captured_objects = args[:objects]
          [{ "result" => { "status" => "SUCCESS" } }]
        end

        client.write(sync_config_with_schema, [records.first])

        expect(captured_objects.first[:properties]["age"]).to eq(30)
        expect(captured_objects.first[:properties]["age"]).to be_an(Integer)
      end
    end

    context "when records array is empty" do
      it "returns tracking with zero counts" do
        allow(client).to receive(:build_client).and_return(weaviate_client)
        allow(objects_resource).to receive(:batch_create).and_return([])

        message = client.write(sync_config_with_schema, [])
        tracking = message.tracking

        expect(tracking.success).to eq(0)
        expect(tracking.failed).to eq(0)
      end
    end
  end

  describe "#normalize_url" do
    subject { client.send(:normalize_url, url) }

    context "with no scheme" do
      let(:url) { "mycluster.weaviate.network" }
      it { is_expected.to eq("https://mycluster.weaviate.network") }
    end

    context "with www. prefix" do
      let(:url) { "www.mycluster.weaviate.network" }
      it { is_expected.to eq("https://mycluster.weaviate.network") }
    end

    context "with https:// already present" do
      let(:url) { "https://mycluster.weaviate.network" }
      it { is_expected.to eq("https://mycluster.weaviate.network") }
    end

    context "with http:// scheme" do
      let(:url) { "http://mycluster.weaviate.network" }
      it { is_expected.to eq("http://mycluster.weaviate.network") }
    end

    context "with trailing slash" do
      let(:url) { "https://mycluster.weaviate.network/" }
      it { is_expected.to eq("https://mycluster.weaviate.network") }
    end

    context "with leading/trailing spaces" do
      let(:url) { "  mycluster.weaviate.network  " }
      it { is_expected.to eq("https://mycluster.weaviate.network") }
    end

    context "with uppercase scheme" do
      let(:url) { "HTTPS://mycluster.weaviate.network" }
      it { is_expected.to eq("https://mycluster.weaviate.network") }
    end

    context "with www. and trailing slash combined" do
      let(:url) { "www.mycluster.weaviate.network/" }
      it { is_expected.to eq("https://mycluster.weaviate.network") }
    end
  end

  describe "#build_client" do
    it "creates a Weaviate::Client with normalized URL and api_key" do
      expect(::Weaviate::Client).to receive(:new).with(
        url: "https://my-instance.weaviate.cloud",
        api_key: "test-key",
        logger: anything
      ).and_call_original

      client.send(:build_client, connection_config)
    end

    it "strips www. prefix from URL" do
      expect(::Weaviate::Client).to receive(:new).with(
        url: "https://my-instance.weaviate.cloud",
        api_key: "test-key",
        logger: anything
      ).and_call_original

      client.send(:build_client, { api_url: "www.my-instance.weaviate.cloud", api_key: "test-key" })
    end

    it "prepends https:// when scheme is missing" do
      expect(::Weaviate::Client).to receive(:new).with(
        url: "https://my-instance.weaviate.cloud",
        api_key: "test-key",
        logger: anything
      ).and_call_original

      client.send(:build_client, { api_url: "my-instance.weaviate.cloud", api_key: "test-key" })
    end
  end

  describe "#generate_uuid" do
    it "returns a valid UUID-formatted string" do
      result = client.send(:generate_uuid, "some-id")
      expect(result).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it "is deterministic — same input produces same UUID" do
      expect(client.send(:generate_uuid, "abc")).to eq(client.send(:generate_uuid, "abc"))
    end

    it "produces different UUIDs for different inputs" do
      expect(client.send(:generate_uuid, "abc")).not_to eq(client.send(:generate_uuid, "xyz"))
    end

    it "handles empty string without error" do
      expect { client.send(:generate_uuid, "") }.not_to raise_error
    end
  end

  describe "#coerce_properties" do
    let(:stream) do
      Multiwoven::Integrations::Protocol::Stream.from_json({
        name: "Test",
        action: "create",
        json_schema: {
          type: "object",
          properties: {
            properties: {
              type: "object",
              properties: {
                count: { type: "integer" },
                price: { type: "number" },
                active: { type: "boolean" },
                label: { type: "string" }
              }
            }
          }
        }
      }.to_json)
    end

    it "coerces integer string to integer" do
      result = client.send(:coerce_properties, { "count" => "3" }, stream)
      expect(result["count"]).to eq(3)
      expect(result["count"]).to be_an(Integer)
    end

    it "coerces number string to float" do
      result = client.send(:coerce_properties, { "price" => "9.99" }, stream)
      expect(result["price"]).to eq(9.99)
      expect(result["price"]).to be_a(Float)
    end

    it "coerces boolean string to boolean" do
      result = client.send(:coerce_properties, { "active" => "true" }, stream)
      expect(result["active"]).to eq(true)
    end

    it "passes string values through unchanged" do
      result = client.send(:coerce_properties, { "label" => "hello" }, stream)
      expect(result["label"]).to eq("hello")
    end

    it "passes through unknown keys without error" do
      result = client.send(:coerce_properties, { "unknown_field" => "value" }, stream)
      expect(result["unknown_field"]).to eq("value")
    end

    it "handles nil values without error" do
      result = client.send(:coerce_properties, { "count" => nil }, stream)
      expect(result["count"]).to eq(0)
    end
  end

  describe "#meta_data" do
    it "matches class name with meta.json name" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end
  end
end
