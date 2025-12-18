# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Tool, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
  end

  describe "enums" do
    it { should define_enum_for(:tool_type).with_values(mcp: 0) }
  end

  describe "validations" do
    subject { build(:tool) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:workspace_id).case_insensitive }
    it { should validate_presence_of(:tool_type) }
    it { should validate_presence_of(:configuration) }

    context "with valid MCP configuration" do
      it "is valid with all required fields" do
        tool = build(:tool)
        expect(tool).to be_valid
      end

      it "is valid with sse transport" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "bearer"
                     })
        expect(tool).to be_valid
      end

      it "is valid with http transport" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/api",
                       "transport" => "http",
                       "auth_type" => "api_key"
                     })
        expect(tool).to be_valid
      end
    end

    context "with invalid MCP configuration" do
      it "is invalid without url" do
        tool = build(:tool, configuration: {
                       "transport" => "sse",
                       "auth_type" => "bearer"
                     })
        expect(tool).not_to be_valid
        expect(tool.errors[:configuration]).to be_present
      end

      it "is invalid without transport" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "auth_type" => "bearer"
                     })
        expect(tool).not_to be_valid
        expect(tool.errors[:configuration]).to be_present
      end

      it "is invalid without auth_type" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse"
                     })
        expect(tool).not_to be_valid
        expect(tool.errors[:configuration]).to be_present
      end

      it "is invalid with unsupported transport type" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "websocket",
                       "auth_type" => "bearer"
                     })
        expect(tool).not_to be_valid
        expect(tool.errors[:configuration]).to be_present
      end

      it "is invalid with unsupported auth_type" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "oauth2"
                     })
        expect(tool).not_to be_valid
        expect(tool.errors[:configuration]).to be_present
      end
    end
  end

  describe "default scope" do
    let(:workspace) { create(:workspace) }
    let!(:tool1) { create(:tool, workspace:, name: "Tool 1", updated_at: 1.day.ago) }
    let!(:tool2) { create(:tool, workspace:, name: "Tool 2", updated_at: 2.days.ago) }
    let!(:tool3) { create(:tool, workspace:, name: "Tool 3", updated_at: 3.hours.ago) }

    it "orders by updated_at in descending order" do
      result = Agents::Tool.all
      expect(result.to_a).to eq([tool3, tool1, tool2])
    end

    it "can be overridden with explicit order" do
      result = Agents::Tool.unscoped.order(:name)
      expect(result.map(&:name)).to eq(["Tool 1", "Tool 2", "Tool 3"])
    end
  end

  describe "#connection_config" do
    context "when tool is MCP type" do
      it "returns connection configuration hash" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "bearer",
                       "auth_config" => { "secret" => "test_token" },
                       "headers" => { "X-Custom" => "value" },
                       "timeout" => 60
                     })

        config = tool.connection_config

        expect(config[:url]).to eq("https://mcp.example.com/sse")
        expect(config[:transport]).to eq("sse")
        expect(config[:auth_type]).to eq("bearer")
        expect(config[:auth_config]).to eq({ "secret" => "test_token" })
        expect(config[:headers]).to eq({ "X-Custom" => "value" })
        expect(config[:timeout]).to eq(60)
      end

      it "returns default timeout when not specified" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "bearer"
                     })

        config = tool.connection_config

        expect(config[:timeout]).to eq(30)
      end

      it "returns empty hash for headers when not specified" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "bearer"
                     })

        config = tool.connection_config

        expect(config[:headers]).to eq({})
      end

      it "returns empty hash for auth_config when not specified" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "none"
                     })

        config = tool.connection_config

        expect(config[:auth_config]).to eq({})
      end
    end

    context "when configuration is nil" do
      it "returns empty hash" do
        tool = build(:tool)
        tool.configuration = nil

        expect(tool.connection_config).to eq({})
      end
    end
  end

  describe "#masked_configuration" do
    context "when tool is MCP type" do
      it "masks secrets in auth_config" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "bearer",
                       "auth_config" => {
                         "secret" => "super_secret_token"
                       }
                     })

        masked = tool.masked_configuration

        expect(masked["url"]).to eq("https://mcp.example.com/sse")
        expect(masked["transport"]).to eq("sse")
        expect(masked["auth_type"]).to eq("bearer")
        expect(masked["auth_config"]["secret"]).to eq("*************")
      end

      it "masks all string values in auth_config" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/api",
                       "transport" => "http",
                       "auth_type" => "basic",
                       "auth_config" => {
                         "username" => "test_user",
                         "password" => "test_password"
                       }
                     })

        masked = tool.masked_configuration

        expect(masked["auth_config"]["username"]).to eq("*************")
        expect(masked["auth_config"]["password"]).to eq("*************")
      end

      it "does not mask non-string values" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "bearer",
                       "auth_config" => {
                         "secret" => "token",
                         "retry_count" => 3
                       },
                       "timeout" => 60
                     })

        masked = tool.masked_configuration

        expect(masked["auth_config"]["retry_count"]).to eq(3)
        expect(masked["timeout"]).to eq(60)
      end

      it "handles missing auth_config gracefully" do
        tool = build(:tool, configuration: {
                       "url" => "https://mcp.example.com/sse",
                       "transport" => "sse",
                       "auth_type" => "none"
                     })

        masked = tool.masked_configuration

        expect(masked["url"]).to eq("https://mcp.example.com/sse")
        expect(masked["auth_config"]).to be_nil
      end
    end

    context "when configuration is nil" do
      it "returns nil" do
        tool = build(:tool)
        tool.configuration = nil

        expect(tool.masked_configuration).to be_nil
      end
    end

    context "when configuration is empty" do
      it "returns empty configuration" do
        tool = build(:tool)
        # Bypass validation for testing
        tool.instance_variable_set(:@configuration, {})
        allow(tool).to receive(:configuration).and_return({})

        expect(tool.masked_configuration).to eq({})
      end
    end
  end

  describe "workspace association" do
    let(:workspace) { create(:workspace) }

    it "can have multiple tools" do
      tool1 = create(:tool, workspace:, name: "Tool 1")
      tool2 = create(:tool, workspace:, name: "Tool 2")
      tool3 = create(:tool, workspace:, name: "Tool 3")

      expect(workspace.tools).to include(tool1, tool2, tool3)
      expect(workspace.tools.count).to eq(3)
    end

    it "deletes all tools when workspace is deleted" do
      tool1 = create(:tool, workspace:, name: "Tool 1")
      tool2 = create(:tool, workspace:, name: "Tool 2")

      expect do
        workspace.destroy
      end.to change { Agents::Tool.count }.by(-2)

      expect(Agents::Tool.exists?(tool1.id)).to be false
      expect(Agents::Tool.exists?(tool2.id)).to be false
    end
  end

  describe "factory traits" do
    it "creates a tool with api_key auth" do
      tool = create(:tool, :with_api_key_auth)
      expect(tool.configuration["auth_type"]).to eq("api_key")
      expect(tool.configuration["auth_config"]["header_name"]).to eq("X-API-Key")
    end

    it "creates a tool with basic auth" do
      tool = create(:tool, :with_basic_auth)
      expect(tool.configuration["auth_type"]).to eq("basic")
      expect(tool.configuration["auth_config"]["username"]).to be_present
      expect(tool.configuration["auth_config"]["password"]).to be_present
    end

    it "creates a tool with no auth" do
      tool = create(:tool, :with_no_auth)
      expect(tool.configuration["auth_type"]).to eq("none")
    end

    it "creates a disabled tool" do
      tool = create(:tool, :disabled)
      expect(tool.enabled).to be false
    end

    it "creates a Slack MCP tool" do
      tool = create(:tool, :slack)
      expect(tool.name).to eq("Slack MCP")
      expect(tool.configuration["url"]).to eq("https://mcp.slack.com/sse")
      expect(tool.metadata["category"]).to eq("team_collaboration")
    end

    it "creates a GitHub MCP tool" do
      tool = create(:tool, :github)
      expect(tool.name).to eq("GitHub MCP")
      expect(tool.configuration["url"]).to eq("https://mcp.run/dylibso/github")
      expect(tool.metadata["category"]).to eq("developer_tools")
    end
  end

  describe "uniqueness constraint" do
    let(:workspace) { create(:workspace) }

    it "allows same name in different workspaces" do
      other_workspace = create(:workspace)
      create(:tool, workspace:, name: "Shared Tool")
      tool = build(:tool, workspace: other_workspace, name: "Shared Tool")

      expect(tool).to be_valid
    end

    it "does not allow duplicate names in same workspace" do
      create(:tool, workspace:, name: "Unique Tool")
      tool = build(:tool, workspace:, name: "Unique Tool")

      expect(tool).not_to be_valid
      expect(tool.errors[:name]).to be_present
    end

    it "is case insensitive for name uniqueness" do
      create(:tool, workspace:, name: "My Tool")
      tool = build(:tool, workspace:, name: "MY TOOL")

      expect(tool).not_to be_valid
      expect(tool.errors[:name]).to be_present
    end
  end
end
