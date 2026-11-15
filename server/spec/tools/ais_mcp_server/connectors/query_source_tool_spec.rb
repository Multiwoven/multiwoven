# frozen_string_literal: true

require "rails_helper"
require "support/shared_contexts/mcp_tool_context"

RSpec.describe AisMcpServer::Connectors::QuerySourceTool do
  include_context "mcp tool setup"

  let!(:connector) { create(:connector, workspace:, connector_type: "source") }

  let(:query_result) do
    [
      double(record: double(data: { "id" => 1, "name" => "test" })),
      double(record: double(data: { "id" => 2, "name" => "test2" }))
    ]
  end

  before do
    allow_any_instance_of(Connector).to receive(:execute_query).and_return(query_result)
  end

  describe "#call" do
    it "returns query results as JSON with pagination metadata" do
      result = JSON.parse(tool_as(admin_user).call(id: connector.id, query: "SELECT * FROM users"))
      expect(result["data"]).to eq(
        [
          { "id" => 1, "name" => "test" },
          { "id" => 2, "name" => "test2" }
        ]
      )
      expect(result["page"]).to eq(1)
      expect(result["per_page"]).to eq(50)
    end

    it "applies pagination with LIMIT and OFFSET" do
      expect(::Connectors::QuerySource).to receive(:call)
        .with(connector:, query: "SELECT 1 LIMIT 10 OFFSET 20", limit: 10)
        .and_return(double(success?: true, records: query_result))

      tool_as(admin_user).call(id: connector.id, query: "SELECT 1", page: 3, per_page: 10)
    end

    it "defaults to page 1 and per_page 50" do
      expect(::Connectors::QuerySource).to receive(:call)
        .with(connector:, query: "SELECT 1 LIMIT 50 OFFSET 0", limit: 50)
        .and_return(double(success?: true, records: query_result))

      tool_as(admin_user).call(id: connector.id, query: "SELECT 1")
    end

    it "strips trailing semicolons before applying pagination" do
      expect(::Connectors::QuerySource).to receive(:call)
        .with(connector:, query: "SELECT 1 LIMIT 50 OFFSET 0", limit: 50)
        .and_return(double(success?: true, records: query_result))

      tool_as(admin_user).call(id: connector.id, query: "SELECT 1;")
    end

    it "strips trailing whitespace and semicolons" do
      expect(::Connectors::QuerySource).to receive(:call)
        .with(connector:, query: "SELECT 1 LIMIT 50 OFFSET 0", limit: 50)
        .and_return(double(success?: true, records: query_result))

      tool_as(admin_user).call(id: connector.id, query: "SELECT 1;  ")
    end

    it "returns correct page and per_page in response" do
      result = JSON.parse(
        tool_as(admin_user).call(id: connector.id, query: "SELECT 1", page: 2, per_page: 25)
      )
      expect(result["page"]).to eq(2)
      expect(result["per_page"]).to eq(25)
    end

    it "computes correct offset for page 1" do
      expect(::Connectors::QuerySource).to receive(:call)
        .with(connector:, query: "SELECT 1 LIMIT 10 OFFSET 0", limit: 10)
        .and_return(double(success?: true, records: query_result))

      tool_as(admin_user).call(id: connector.id, query: "SELECT 1", page: 1, per_page: 10)
    end

    it "computes correct offset for page 5 with per_page 20" do
      expect(::Connectors::QuerySource).to receive(:call)
        .with(connector:, query: "SELECT 1 LIMIT 20 OFFSET 80", limit: 20)
        .and_return(double(success?: true, records: query_result))

      tool_as(admin_user).call(id: connector.id, query: "SELECT 1", page: 5, per_page: 20)
    end

    it "returns empty data array when query returns no records" do
      expect(::Connectors::QuerySource).to receive(:call)
        .and_return(double(success?: true, records: []))

      result = JSON.parse(tool_as(admin_user).call(id: connector.id, query: "SELECT 1", page: 100))
      expect(result["data"]).to eq([])
      expect(result["page"]).to eq(100)
      expect(result["per_page"]).to eq(50)
    end

    it "handles multi-line queries" do
      multi_line_query = "SELECT *\nFROM users\nWHERE id > 0"
      expect(::Connectors::QuerySource).to receive(:call)
        .with(connector:, query: "#{multi_line_query} LIMIT 50 OFFSET 0", limit: 50)
        .and_return(double(success?: true, records: query_result))

      tool_as(admin_user).call(id: connector.id, query: multi_line_query)
    end

    it "raises an instructive error when query contains LIMIT clause" do
      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT * FROM users LIMIT 10")
      end.to raise_error(ArgumentError, /use the page and per_page arguments instead/)
    end

    it "raises an instructive error when query contains OFFSET clause" do
      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT * FROM users OFFSET 5")
      end.to raise_error(ArgumentError, /use the page and per_page arguments instead/)
    end

    %w[DELETE DROP TRUNCATE ALTER INSERT UPDATE].each do |keyword|
      it "raises when query starts with #{keyword}" do
        expect do
          tool_as(admin_user).call(id: connector.id, query: "#{keyword} FROM users")
        end.to raise_error(Utils::ReadOnlyQueryGate::QueryRejectedError)
      end
    end

    it "raises when SELECT contains destructive subquery" do
      expect do
        tool_as(admin_user).call(
          id: connector.id,
          query: "SELECT * FROM users; DROP TABLE users"
        )
      end.to raise_error(Utils::ReadOnlyQueryGate::QueryRejectedError, /multiple statements/)
    end

    it "allows SELECT from tables with destructive-sounding names" do
      expect(::Connectors::QuerySource).to receive(:call)
        .and_return(double(success?: true, records: query_result))

      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT * FROM delete_logs")
      end.not_to raise_error
    end

    it "raises when connector is not a source" do
      destination = create(:connector, workspace:, connector_type: "destination")

      expect do
        tool_as(admin_user).call(id: destination.id, query: "SELECT 1")
      end.to raise_error(RuntimeError, /Connector is not a source/)
    end

    it "raises when connector not found" do
      expect do
        tool_as(admin_user).call(id: 999_999, query: "SELECT 1")
      end.to raise_error(RuntimeError, /Connector 999999 not found/)
    end

    it "raises when query fails" do
      expect(::Connectors::QuerySource).to receive(:call)
        .and_return(double(success?: false, error: "Invalid SQL"))

      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT bad_col FROM nonexistent")
      end.to raise_error(RuntimeError, /Invalid SQL/)
    end

    it "raises the Postgres message without reporting when the query references an undefined column" do
      message = 'ERROR:  column "bad_col" does not exist'
      allow_any_instance_of(Connector).to receive(:execute_query).and_raise(PG::UndefinedColumn.new(message))
      expect(Utils::ExceptionReporter).not_to receive(:report)

      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT bad_col FROM users")
      end.to raise_error(RuntimeError, /column "bad_col" does not exist/)
    end

    it "reports the exception when the source connection fails" do
      error = PG::ConnectionBad.new("connection to server failed")
      allow_any_instance_of(Connector).to receive(:execute_query).and_raise(error)
      expect(Utils::ExceptionReporter).to receive(:report).with(error)

      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT 1")
      end.to raise_error(RuntimeError, /connection to server failed/)
    end

    it "raises a clear error when the connector does not support querying" do
      allow_any_instance_of(Connector).to receive(:execute_query).and_return(nil)

      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT 1")
      end.to raise_error(RuntimeError, "This connector does not support querying")
    end

    it "raises when connector belongs to a different workspace" do
      other_workspace = create(:workspace)
      other_connector = create(:connector, workspace: other_workspace, connector_type: "source")

      expect do
        tool_as(admin_user).call(id: other_connector.id, query: "SELECT 1")
      end.to raise_error(RuntimeError, /Connector #{other_connector.id} not found/)
    end
  end

  describe "role-based authorization" do
    it "allows admin users" do
      expect do
        tool_as(admin_user).call(id: connector.id, query: "SELECT 1")
      end.not_to raise_error
    end

    it "allows member users" do
      expect do
        tool_as(member_user).call(id: connector.id, query: "SELECT 1")
      end.not_to raise_error
    end

    it "allows viewer users" do
      expect do
        tool_as(viewer_user).call(id: connector.id, query: "SELECT 1")
      end.not_to raise_error
    end
  end

  describe "tool metadata" do
    it "has correct tool_name" do
      expect(described_class.tool_name).to eq("connectors_query_source")
    end
  end
end
