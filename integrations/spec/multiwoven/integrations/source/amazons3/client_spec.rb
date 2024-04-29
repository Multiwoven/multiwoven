# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::AmazonS3::Client do # rubocop:disable Metrics/BlockLength
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      region: "region",
      bucket: "bucket",
      access_id: "accessid",
      secret_access: "secretaccess",
      file_key: "filekey"
    }
  end

  let(:sync_config_json) do
    { source: {
        name: "AmazonS3",
        type: "source",
        connection_specification: connection_config
      },
      destination: {
        name: "Salesforce Consumer Goods Cloud",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM Account LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      # before do
      #   stub_request(:post, "https://login.salesforce.com/services/oauth2/token")
      #     .to_return(status: 200, body: "", headers: {})
      # end

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

  # describe "#read" do
  #   context "when read is successful" do
  #     it "returns an array of MultiwovenMessages with RecordMessages" do
  #       allow(client).to receive(:initialize_client)
  #       allow(client).to receive(:@client).and_return(double)

  #       sobject_one = Restforce::SObject.new("Id" => "1", "Name" => "Random COMPANY")
  #       sobject_two = Restforce::SObject.new("Id" => "2", "Name" => "Random COMPANY 2")
  #       query_result = [sobject_one, sobject_two]

  #       allow(client.instance_variable_get(:@client)).to receive(:query).and_return(query_result)

  #       results = client.read(sync_config)

  #       expect(results).to all(be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage))
  #       expect(results[0].record.data).to eq(sobject_one)
  #       expect(results[1].record.data).to eq(sobject_two)
  #     end
  #   end

  #   context "when read fails" do
  #     it "handles exceptions" do
  #       allow(client).to receive(:initialize_client)
  #       allow(client).to receive(:@client).and_return(double)
  #       allow(client.instance_variable_get(:@client)).to receive(:query).and_raise(StandardError.new("Read failed"))

  #       expect { client.read(sync_config) }.to_not raise_error
  #     end
  #   end
  # end

  # describe "#meta_data" do
  #   it "serves it github image url as icon" do
  #     image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations/lib/multiwoven/integrations/source/salesforce_consumer_goods_cloud/icon.svg"
  #     expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
  #   end
  # end

  # describe "#discover" do
  #   context "when discovery is successful" do
  #     it "returns a MultiwovenMessage with the expected catalog structure" do
  #       allow(client).to receive(:initialize_client).with(connection_config.with_indifferent_access)
  #       allow(client).to receive(:load_catalog).and_return({ streams: [] })

  #       restforce_client_double = double("Restforce client")
  #       allow(client).to receive(:@client).and_return(restforce_client_double)

  #       allow(@client).to receive(:describe).with("Account").and_return(sample_account_description)
  #       allow(@client).to receive(:describe).with("User").and_return(sample_user_description)
  #       allow(@client).to receive(:describe).with("Visit").and_return(sample_account_description)
  #       allow(@client).to receive(:describe).with("RetailStore").and_return(sample_user_description)
  #       allow(@client).to receive(:describe).with("RecordType").and_return(sample_user_description)

  #       allow(client).to receive(:create_json_schema_for_object).and_return(sample_account_schema, sample_user_schema)

  #       result = client.discover(connection_config)
  #       expect(result).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
  #       expect(result.type).to eq("catalog")
  #     end
  #   end

  #   context "when discovery fails" do
  #     it "handles exceptions" do
  #       allow(client).to receive(:initialize_client).with(connection_config.with_indifferent_access)
  #       allow(client).to receive(:load_catalog).and_raise(StandardError.new("Discovery failed"))

  #       expect { client.discover(connection_config) }.to_not raise_error
  #     end
  #   end
  # end

  # describe "#flatten_nested_hash" do
  #   it "returns a flattened hash" do
  #     record =
  #       {
  #         attributes: {
  #           type: "Visit",
  #           url: "/services/data/v59.0/sobjects/Visit/0Z51U000000bvweSAA"
  #         },
  #         User: {
  #           attributes: {
  #             type: "User",
  #             url: "/services/data/v59.0/sobjects/User/0051U00000860MrQAI"
  #           },
  #           Username: "fl016465@cona.com.lfln011",
  #           Test: {
  #             attributes: {
  #               type: "User",
  #               url: "/services/data/v59.0/sobjects/User/0051U00000860MrQAI"
  #             },
  #             Sample: "sample"

  #           }

  #         },
  #         RecordType: {
  #           attributes: {
  #             type: "RecordType",
  #             url: "/services/data/v59.0/sobjects/RecordType/0121U000000eLVMQA2"
  #           },
  #           Name: "Picture of Success Visit"
  #         },
  #         Account: {
  #           attributes: {
  #             type: "Account",
  #             url: "/services/data/v59.0/sobjects/Account/0011U00001RpDYCQA3"
  #           },
  #           AccountNumber: "0600370301",
  #           OnboardedAccountNumber__c: nil
  #         },
  #         PlannedVisitStartTime: "2021-03-23T13:00:00.000+0000",
  #         PlannedVisitEndTime: "2021-03-23T13:30:00.000+0000"
  #       }.with_indifferent_access

  #     expected_result = {
  #       User_Username: "fl016465@cona.com.lfln011",
  #       RecordType_Name: "Picture of Success Visit",
  #       Account_AccountNumber: "0600370301",
  #       Account_OnboardedAccountNumber__c: nil,
  #       PlannedVisitStartTime: "2021-03-23T13:00:00.000+0000",
  #       PlannedVisitEndTime: "2021-03-23T13:30:00.000+0000",
  #       User_Test_Sample: "sample"
  #     }.with_indifferent_access

  #     result = client.send(:flatten_nested_hash, record)
  #     expect(result).to eq(expected_result)
  #   end
  # end

  private

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end
end
