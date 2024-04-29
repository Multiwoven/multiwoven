# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Airtable::Client do # rubocop:disable Metrics/BlockLength
    include WebMock::API

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

    let(:tickets) do
        [
            build_ticket("test 1", "testing creating a ticket"),
            build_ticket("test 2", "testing creating a ticket")
        ]
    end

    describe "#check_connection" do
        context "when the connection is successful" do
            before do
                stub_request(:post, "#{ZENDESK_TICKETING_URL}/tickets.json")
                    .to_return(
                    status: 201,  # Updated status code to 201 Created
                    body: {
                        "ticket": {
                        "url": "#{ZENDESK_TICKETING_URL}/tickets/123.json"
                        }
                    }.to_json, headers: {})
            end

            it "returns a successful connection status" do
                response = client.check_connection(connection_config)

                expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
                expect(response.connection_status.status).to eq("succeeded")
            end
        end

        context "when the connection fails" do
            before do
                stub_request(:post, "")
                  .to_return(status: 200, body: { "ok": false, "error": "not_authed"}.to_json, headers: {})
            end

            it "returns a failed connection status with an error message" do 
                response = client.check_connection(connection_config)

                expect(response).to be_a(Multiwoven::Integrations::Protocol:MultiwovenMessage)
                expect(response.connection_status.status).to eq("failed")
                expect(response.connection_status.message).to eq("not_authed")
            end
        end
    end

    describe "#discover" do
        # ...
    end

    describe "#write" do
        # ...
    end

    describe "#create_payload" do
        # ...
    end

    private

    def build_ticket(subject, body)
        {"ticket": {"subject": subject, "comment": {"body": body}}}
    end
end