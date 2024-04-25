# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Airtable::Client do # rubocop:disable Metrics/BlockLength
    include WebMock::API

    before(:each) do
        WebMock.disable_net_connect!(allow_localhost: true)
    end

    let(:client) { described_class.new }
    
    let(:connection_config) do
        {
            url: "https://yoursubdomain.zendesk.com/api/v2"
            username: "test_user",
            token: "test_token",
        }
    end

    let(:json_schema) do
        # ...  
    end

    describe "#check_connection" do
        # ...
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
end