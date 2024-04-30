# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Zendesk::Client do
    include WebMock::API
    ZENDESK_TICKETING_URL = "https://multiwoven-test.zendesk.com/api/v2"
    
    before(:each) do
        WebMock.disable_net_connect!(allow_localhost: true)
    end

    let(:client) { described_class.new }
    
    let(:connection_config) do
        {
            username: "praneeth.chandu@squared.ai",
            password: "Welcome123"
        }
    end

    let(:records) do
        [
            {"ticket": {"subject": "test 1", "comment": {"body": "testing creating a ticket"}}},
            {"ticket": {"subject": "test 2", "comment": {"body": "testing creating a ticket"}}}
        ]
    end

    let(:sync_config) do
        Multiwoven::Integrations::Protocol::SyncConfig.new(
            source: source_connector,
            destination: destination_connector,
            model: model,
            stream: stream,
            sync_mode: Multiwoven::Integrations::Protocol::SyncMode['incremental'],
            destination_sync_mode: Multiwoven::Integrations::Protocol::DestinationSyncMode['insert']
        )
    end

    
    describe "#check_connection" do
        before do
            allow(client).to receive(:initialize_client).and_return(true)
            allow(client).to receive(:authenticate_client).and_return(true)
        end

        context "when the connection is successful" do
            it "returns a successful connection status" do
                response = client.check_connection(connection_config)
                expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
                expect(response.connection_status.status).to eq("succeeded")
            end
        end
        
        
        context "when the connection fails" do
            before do
                allow(client).to receive(:initialize_client).and_raise(StandardError, "Connection failed")
            end

            it "returns a failed connection status" do
                response = client.check_connection(connection_config)
                expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
                expect(response.connection_status.status).to eq("failed")
            end
        end
    end

    # describe "#discover" do
    #     before do
    #         stub_request(:get, "#{ZENDESK_TICKETING_URL}/ticket_fields.json")
    #         .to_return(status: 200, body: '{"ticket_fields": [{"id": 1, "title": "Subject"}]}', headers: {})
    #     end

    #     it "fetches and returns the schema for tickets" do
    #         catalog = client.discover
    #         expect(catalog.streams.first.json_schema['properties']).to include("subject")
    #     end
    # end

    # describe "#write" do
    #     context "when tickets are successfully created" do
    #         before do
    #             tickets.each do |ticket|
    #             stub_request(:post, "#{ZENDESK_TICKETING_URL}/tickets.json")
    #                 .with(body: ticket.to_json)
    #                 .to_return(status: 201, body: '{"ticket": {"id": 123, "subject": "Ticket created"}}', headers: {})
    #             end
    #         end

    #         it "increments the success count for each ticket" do
    #             result = client.write(sync_config, tickets, "create")
    #             expect(result[:success]).to eq(tickets.size)
    #             expect(result[:failures]).to eq(0)
    #         end
    #     end

    #     context "when ticket creation fails" do
    #         before do
    #             tickets.each do |ticket|
    #             stub_request(:post, "#{ZENDESK_TICKETING_URL}/tickets.json")
    #                 .with(body: ticket.to_json)
    #                 .to_return(status: 400, body: '{"error": "Bad Request"}', headers: {})
    #             end
    #         end

    #         it "increments the failure count for each ticket" do
    #             result = client.write(sync_config, tickets, "create")
    #             expect(result[:success]).to eq(0)
    #             expect(result[:failures]).to eq(tickets.size)
    #         end
    #     end
    # end
end