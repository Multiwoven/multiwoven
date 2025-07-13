# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Odoo::Client do
  let(:client) { Multiwoven::Integrations::Destination::Odoo::Client.new }
  let(:error_instance) { StandardError.new("Odoo source error") }
  let(:connection_config) do
    {
      url: "http://localhost:8069",
      database: "database",
      username: "username",
      password: "password"
    }
  end
  let(:common_endpoint) { "#{connection_config[:url]}/xmlrpc/2/common" }
  let(:object_endpoint) { "#{connection_config[:url]}/xmlrpc/2/object" }
  let(:sync_config_json) do
    {
      source: {
        name: "Sample Source Connector",
        type: "source",
        connection_specification: {
          private_api_key: "your_key"
        }
      },
      destination: {
        name: "Odoo",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "account",
        query: "SELECT * FROM account LIMIT 50",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "account",
        request_method: "POST",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: {}
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      sync_id: "1",
      sync_run_id: nil
    }
  end

  before do
    stub_request(:post, common_endpoint)
      .with({
              body: "<?xml version=\"1.0\" ?><methodCall><methodName>version</methodName><params/></methodCall>\n"
            }).to_return(status: 200, body: XMLRPC::Create.new.methodResponse(true, {}), headers: {})
    stub_request(:post, common_endpoint)
      .with({
              body: "<?xml version=\"1.0\" ?><methodCall><methodName>authenticate</methodName><params><param><value>"\
              "<string>database</string></value></param><param><value><string>username</string></value></param><param>"\
              "<value><string>password</string></value></param><param><value><struct><member><name>raise_exception</name>"\
              "<value><boolean>1</boolean></value></member></struct></value></param></params></methodCall>\n"
            }).to_return(status: 200, body: XMLRPC::Create.new.methodResponse(true, 1), headers: {})
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a successful connection status" do
        message = client.check_connection(connection_config)
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end
    context "when the connection is unsuccessful" do
      it "returns an unsucessful connection status" do
        allow(client).to receive(:create_connection).and_raise(error_instance)
        message = client.check_connection(connection_config)
        result = message.connection_status
        expect(result.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    context "when discover is successful" do
      before do
        models = [{ model: "account" }]
        stub_request(:post, object_endpoint)
          .with({
                  body: "<?xml version=\"1.0\" ?><methodCall><methodName>execute_kw</methodName><params><param><value><string>"\
                  "database</string></value></param><param><value><i4>1</i4></value></param><param><value><string>password</string>"\
                  "</value></param><param><value><string>ir.model</string></value></param><param><value><string>search_read</string>"\
                  "</value></param><param><value><array><data><value><array><data><value><array><data><value><string>transient</string>"\
                  "</value><value><string>=</string></value><value><boolean>0</boolean></value></data></array></value><value>"\
                  "<array><data><value><string>abstract</string></value><value><string>=</string></value><value><boolean>0</boolean>"\
                  "</value></data></array></value></data></array></value></data></array></value></param><param><value><struct>"\
                  "<member><name>fields</name><value><array><data><value><string>name</string></value><value><string>model</string>"\
                  "</value></data></array></value></member></struct></value></param></params></methodCall>\n"
                })
          .to_return(status: 200, body: XMLRPC::Create.new.methodResponse(true, models), headers: {})

        fields = [[[], { name: "field", type: "string" }]]
        stub_request(:post, object_endpoint)
          .with({
                  body: "<?xml version=\"1.0\" ?><methodCall><methodName>execute_kw</methodName><params><param><value>"\
                  "<string>database</string></value></param><param><value><i4>1</i4></value></param><param><value><string>password</string>"\
                  "</value></param><param><value><string>account</string></value></param><param><value><string>fields_get</string></value>"\
                  "</param><param><value><array><data/></array></value></param><param><value><struct><member><name>attributes</name>"\
                  "<value><array><data><value><string>name</string></value><value><string>type</string></value></data></array></value>"\
                  "</member></struct></value></param></params></methodCall>\n"
                })
          .to_return(status: 200, body: XMLRPC::Create.new.methodResponse(true, fields), headers: {})
      end
      it "returns a catalog" do
        message = client.discover(connection_config)
        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
        first_stream = message.catalog.streams.first
        expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(first_stream.name).to eq("account")
        expect(first_stream.json_schema).to be_an(Hash)
        expect(first_stream.json_schema["type"]).to eq("object")
        expect(first_stream.json_schema["properties"]).to eq({ "field" => { "type" => "string" } })
      end
    end
    context "when discover is unsuccesful" do
      it "handles exceptions during discovery" do
        allow(client).to receive(:create_connection).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          {
            context: "ODOO:DISCOVER:EXCEPTION",
            type: "error"
          }
        )
        client.discover(connection_config)
      end
    end
  end

  describe "#write" do
    let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
    let(:records) do
      [
        {
          id: 1,
          name: "record"
        }
      ]
    end
    context "when the write operation is successful" do
      before do
        stub_request(:post, object_endpoint)
          .with({
                  body: "<?xml version=\"1.0\" ?><methodCall><methodName>execute_kw</methodName><params><param><value><string>database</string>"\
                  "</value></param><param><value><i4>1</i4></value></param><param><value><string>password</string></value></param><param><value>"\
                  "<string>account</string></value></param><param><value><string>create</string></value></param><param><value><array><data><value>"\
                  "<struct><member><name>id</name><value><i4>1</i4></value></member><member><name>name</name><value><string>record</string></value>"\
                  "</member></struct></value></data></array></value></param></params></methodCall>\n"
                })
          .to_return(status: 200, body: XMLRPC::Create.new.methodResponse(true, records))
      end
      it "raises the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json)
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
    context "when the write operation is not successful" do
      before do
        stub_request(:post, object_endpoint).and_raise(error_instance)
      end
      it "raises the failure count" do
        message = client.write(sync_config, records)
        tracker = message.tracking

        expect(tracker.success).to eq(0)
        expect(tracker.failed).to eq(1)

        log_message = tracker.logs.first
        expect(log_message.level).to eql("error")
        expect(log_message.message).to include("Odoo source error")
      end
    end
    context "when the write operation throws an exception" do
      it "handles the exception" do
        allow(client).to receive(:create_connection).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          {
            context: "ODOO:WRITE:EXCEPTION",
            type: "error",
            sync_id: "1",
            sync_run_id: nil
          }
        )
        client.write(sync_config, records)
      end
    end
  end
end
