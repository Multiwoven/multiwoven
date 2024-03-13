# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Stripe::Client do
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      api_key: "api_key"
    }
  end

  let(:stripe_customer_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "Customer" }.json_schema
  end

  let(:sync_config_json) do
    { source: {
        name: "SourceConnectorName",
        type: "source",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Stripe",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM CALL_CENTER LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "Customer",
        action: "create",
        json_schema: stripe_customer_json_schema
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:records) do
    [
      { name: "John Doe", email: "john@example.com" },
      { name: "Jane Doe", email: "jane@example.com" }
    ]
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        stub_request(:post, "https://api.stripe.com/v1/customers")
          .to_return(status: 200, body: "", headers: {})
      end

      it "returns a successful connection status" do
        allow(client).to receive(:authenticate_client).and_return(true)

        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:authenticate_client).and_raise(StandardError.new("connection failed"))

        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
        expect(response.connection_status.message).to eq("connection failed")
      end
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        allow(Stripe::Customer).to receive(:create).and_return(true)
      end

      it "increments the success count" do
        response = client.write(sync_config, records)

        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      before do
        allow(Stripe::Customer).to receive(:create).and_raise(StandardError.new("connection failed"))
      end

      it "increments the failure count" do
        response = client.write(sync_config, records)

        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
      end
    end
  end

  describe "#meta_data" do
    it "serves it github image url as icon" do
      image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven-integrations/#{client.class::MAIN_BRANCH_SHA}/lib/multiwoven/integrations/destination/stripe/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
  end

  private

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      catalog.streams.each do |stream|
        expect(stream.supported_sync_modes).to eql(%w[incremental])
      end
    end
  end
end
