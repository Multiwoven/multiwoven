# frozen_string_literal: true

require "rails_helper"

RSpec.describe LlmUsageLog, type: :model do
  let(:workspace) { create(:workspace) }
  let(:workflow_run) { create(:workflow_run, workspace:) }
  let(:workflow) { create(:workflow, workspace:) }
  let(:component) { create(:component, workflow:, workspace:) }
  let(:connector) { create(:connector, workspace:, connector_name: "OpenAI") }
  let(:llm_usage_log) do
    create(
      :llm_usage_log,
      workspace:,
      workflow_run:,
      component_id: component.id,
      connector_id: connector.id,
      prompt_hash: "test_prompt_hash",
      estimated_input_tokens: 100,
      estimated_output_tokens: 200,
      selected_model: "gpt-4o-mini",
      provider: "openai",
      created_at: 1.day.ago
    )
  end
  let(:llm_usage_log2) do
    create(
      :llm_usage_log,
      workspace:,
      workflow_run:,
      component_id: component.id,
      connector_id: connector.id,
      prompt_hash: "test_prompt_hash",
      estimated_input_tokens: 100,
      estimated_output_tokens: 200,
      selected_model: "gpt-4o-mini",
      provider: "openai",
      created_at: 2.days.ago
    )
  end
  let(:llm_usage_log3) do
    create(
      :llm_usage_log,
      workspace:,
      workflow_run:,
      component_id: component.id,
      connector_id: connector.id,
      prompt_hash: "test_prompt_hash",
      estimated_input_tokens: 100,
      estimated_output_tokens: 200,
      selected_model: "gpt-4o-mini",
      provider: "openai",
      created_at: 3.days.ago
    )
  end

  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:workflow_run) }
    it { should belong_to(:component).class_name("Agents::Component") }
  end

  describe "validations" do
    it { should validate_presence_of(:prompt_hash) }
    it { should validate_presence_of(:estimated_input_tokens) }
    it { should validate_presence_of(:estimated_output_tokens) }
    it { should validate_presence_of(:selected_model) }
    it { should validate_presence_of(:connector_id) }
    it { should validate_presence_of(:component_id) }
    it { should validate_presence_of(:provider) }
  end

  describe "scopes" do
    before do
      llm_usage_log3.update(created_at: 3.days.ago)
      llm_usage_log2.update(created_at: 2.days.ago)
      llm_usage_log.update(created_at: 1.day.ago)
    end
    context "when there are multiple llm usage logs" do
      it "returns the llm usage logs in descending order of created_at (newest first)" do
        expect(described_class.recent.to_a).to eq([llm_usage_log, llm_usage_log2, llm_usage_log3])
      end
    end
  end
end
