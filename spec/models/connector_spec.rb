# frozen_string_literal: true

# == Schema Information
#
# Table name: connectors
#
#  id                      :bigint           not null, primary key
#  workspace_id            :integer
#  connector_type          :integer
#  connector_definition_id :integer
#  configuration           :jsonb
#  name                    :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  connector_name          :string
#
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

  describe "#execute_query" do
    let(:connector) { create(:connector) }
    let(:query) { "SELECT * FROM your_table" }
    let(:limit) { 50 }
    let(:mock_db_connection) { instance_double("DatabaseConnection") }
    let(:mock_result) { [{ "column1" => "value1" }, { "column2" => "value2" }] }

    before do
      allow(connector).to receive(:connector_client).and_return(double("ConnectorClient", new: mock_db_connection))
      allow(mock_db_connection).to receive(:create_connection).and_return(mock_db_connection)
      allow(mock_db_connection).to receive(:exec).and_yield(mock_result)
      allow(mock_db_connection).to receive(:close)
    end

    it "executes the query on the database" do
      expect(mock_db_connection).to receive(:exec).with("#{query} LIMIT #{limit}")
      connector.execute_query(query, limit: 50)
    end

    it "returns the result of the query" do
      expect(connector.execute_query(query, limit: 50)).to eq(mock_result)
    end

    it "closes the database connection" do
      connector.execute_query(query, limit: 50)
      expect(mock_db_connection).to have_received(:close)
    end

    context "when an error occurs" do
      before do
        allow(mock_db_connection).to receive(:exec).and_raise(StandardError)
      end

      it "raises an error" do
        expect { connector.execute_query(query, limit: 50) }.to raise_error(StandardError)
      end

      it "ensures the database connection is closed" do
        begin
          connector.execute_query(query, limit: 50)
        rescue StandardError
          # Ignored for this test
        end
        expect(mock_db_connection).to have_received(:close)
      end
    end

    context "when the query has a trailing semicolon" do
      let(:query) { "SELECT * FROM your_table;" }

      it "removes the trailing semicolon" do
        expect(mock_db_connection).to receive(:exec).with("SELECT * FROM your_table LIMIT #{limit}")
        connector.execute_query(query, limit: 50)
      end
    end

    context "when the query already has a LIMIT clause" do
      let(:query_with_limit) { "SELECT * FROM your_table LIMIT 30" }

      it "does not append an additional LIMIT clause" do
        expect(mock_db_connection).to receive(:exec).with(query_with_limit)
        connector.execute_query(query_with_limit)
      end

      it "returns the result of the query" do
        expect(connector.execute_query(query_with_limit)).to eq(mock_result)
      end
    end
  end
end
