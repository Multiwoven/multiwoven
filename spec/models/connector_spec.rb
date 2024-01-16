# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connector, type: :model do
  subject { described_class.new }

  before do
    allow(subject).to receive(:configuration_schema).and_return({}.to_json)
  end

  context "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_type) }
    it { should validate_presence_of(:configuration) }
    it { should validate_presence_of(:name) }
  end

  context "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:models).dependent(:nullify) }
    it { should have_one(:catalog).dependent(:nullify) }
  end

  describe "#to_protocol" do
    it "returns a protocol connector with correct attributes" do
      connector = Connector.new(
        workspace_id: 1,
        connector_type: :source,
        configuration: { key: "value" }.to_json,
        name: "My Connector",
        connector_name: "Snowflake"
      )

      protocol_connector = connector.to_protocol

      expect(protocol_connector).to be_a(Multiwoven::Integrations::Protocol::Connector)
      expect(protocol_connector.name).to eq(connector.connector_name)
      expect(protocol_connector.type).to eq(connector.connector_type)
      expect(protocol_connector.connection_specification).to eq(connector.configuration)
    end
  end
end
