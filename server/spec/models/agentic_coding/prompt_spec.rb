# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::Prompt, type: :model do
  context "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:status) }
    it { should belong_to(:agentic_coding_app).class_name("AgenticCoding::App") }
    it { should belong_to(:agentic_coding_session).class_name("AgenticCoding::Session") }
    it { should define_enum_for(:role).with_values(user: 0, assistant: 1) }
    it { should define_enum_for(:status).with_values(queued: 0, running: 1, completed: 2, failed: 3) }
  end

  describe "default status" do
    let(:prompt) { described_class.new }

    it "sets default status" do
      expect(prompt.status).to eq("queued")
    end
  end

  describe "context" do
    let(:prompt) { described_class.new }

    it "defaults to empty hash" do
      expect(prompt.context).to eq({})
    end

    it "stores jsonb data" do
      workspace = create(:workspace)
      user = workspace.workspace_users.first.user
      app = create(:agentic_coding_app, workspace:, user:)
      session = create(:agentic_coding_session, :active, agentic_coding_app: app, workspace:, user:)

      prompt = session.prompts.create!(
        agentic_coding_app: app,
        content: "test",
        role: :user,
        status: :queued,
        agent_mode: "code",
        context: { "connectors" => ["conn_1"], "workflows" => ["wf_1"] }
      )

      prompt.reload
      expect(prompt.context).to eq({ "connectors" => ["conn_1"], "workflows" => ["wf_1"] })
    end
  end

  describe "context validation" do
    let(:workspace) { create(:workspace) }
    let(:user) { workspace.workspace_users.first.user }
    let(:app) { create(:agentic_coding_app, workspace:, user:) }
    let(:session) { create(:agentic_coding_session, :active, agentic_coding_app: app, workspace:, user:) }
    let(:base_attrs) do
      { agentic_coding_app: app, content: "test", role: :user, status: :queued, agent_mode: "code" }
    end

    it "allows empty context" do
      prompt = session.prompts.build(base_attrs.merge(context: {}))
      expect(prompt).to be_valid
    end

    it "allows valid context with all keys" do
      prompt = session.prompts.build(base_attrs.merge(
                                       context: { "connectors" => ["c1"], "workflows" => ["w1"], "apis" => ["a1"] }
                                     ))
      expect(prompt).to be_valid
    end

    it "allows valid context with partial keys" do
      prompt = session.prompts.build(base_attrs.merge(context: { "connectors" => ["c1"] }))
      expect(prompt).to be_valid
    end

    it "rejects invalid keys" do
      prompt = session.prompts.build(base_attrs.merge(context: { "invalid_key" => ["val"] }))
      expect(prompt).not_to be_valid
      expect(prompt.errors[:context].first).to include("/invalid_key", "expected schema")
    end

    it "rejects non-array values" do
      prompt = session.prompts.build(base_attrs.merge(context: { "connectors" => "not_an_array" }))
      expect(prompt).not_to be_valid
      expect(prompt.errors[:context].first).to include("/connectors", "expected array")
    end

    it "rejects arrays with non-string elements" do
      prompt = session.prompts.build(base_attrs.merge(context: { "connectors" => [1, 2] }))
      expect(prompt).not_to be_valid
      expect(prompt.errors[:context].first).to include("/connectors/0", "expected string")
    end
  end
end
