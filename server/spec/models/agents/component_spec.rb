# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Component, type: :model do
  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:workspace) }
    it { should have_many(:source_edges).class_name("Agents::Edge").dependent(:destroy) }
    it { should have_many(:target_edges).class_name("Agents::Edge").dependent(:destroy) }
  end

  describe "enums" do
    it {
      should define_enum_for(:component_type).with_values(
        chat_input: 0,
        chat_output: 1,
        data_storage: 2,
        llm_model: 3,
        prompt_template: 4,
        vector_store: 5,
<<<<<<< HEAD
        python_custom: 6
=======
        python_custom: 6,
        conditional: 7,
        guardrails: 8,
        tool: 9,
        agent: 10,
        knowledge_base: 11,
        llm_router: 12,
        human_in_loop: 13,
        a2a_agent: 14
>>>>>>> afa98e94b (feat(CE): add a2a_agent component type, masked config, and JSON-RPC client (#1719))
      )
    }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:component_type) }
  end

  describe "position storage" do
    let(:component) { create(:component) }

    it "stores position as JSON" do
      position_data = { "x" => 100, "y" => 200 }
      component.position = position_data
      component.save
      component.reload
      expect(component.position).to eq(position_data)
    end
  end

  describe "#masked_configuration" do
    context "when component is a2a_agent" do
      let(:component) do
        create(:component, component_type: :a2a_agent, configuration: {
                 "url" => "https://remote-agent.example.com",
                 "auth_type" => "bearer",
                 "auth_config" => { "secret" => "super-secret-token" },
                 "headers" => { "X-Custom" => "value" },
                 "timeout" => 60,
                 "agent_card" => { "name" => "Test Agent" },
                 "skills" => [{ "id" => "s1", "name" => "Skill 1" }]
               })
      end

      it "masks auth_config secret values" do
        masked = component.masked_configuration
        expect(masked["auth_config"]["secret"]).to eq("*************")
      end

      it "preserves non-secret fields" do
        masked = component.masked_configuration
        expect(masked["url"]).to eq("https://remote-agent.example.com")
        expect(masked["auth_type"]).to eq("bearer")
        expect(masked["timeout"]).to eq(60)
        expect(masked["agent_card"]["name"]).to eq("Test Agent")
        expect(masked["skills"].first["name"]).to eq("Skill 1")
      end

      it "does not mutate the original configuration" do
        component.masked_configuration
        expect(component.configuration["auth_config"]["secret"]).to eq("super-secret-token")
      end
    end

    context "when component is a2a_agent with basic auth" do
      let(:component) do
        create(:component, component_type: :a2a_agent, configuration: {
                 "url" => "https://remote-agent.example.com",
                 "auth_type" => "basic",
                 "auth_config" => { "username" => "admin", "secret" => "password123" }
               })
      end

      it "masks all auth_config string values" do
        masked = component.masked_configuration
        expect(masked["auth_config"]["username"]).to eq("*************")
        expect(masked["auth_config"]["secret"]).to eq("*************")
      end
    end

    context "when component is a2a_agent with no auth_config" do
      let(:component) do
        create(:component, component_type: :a2a_agent, configuration: {
                 "url" => "https://remote-agent.example.com",
                 "auth_type" => "none"
               })
      end

      it "returns configuration unchanged" do
        masked = component.masked_configuration
        expect(masked).to eq(component.configuration)
      end
    end

    context "when component is not a2a_agent" do
      let(:component) { create(:component, component_type: :agent) }

      it "returns configuration as-is" do
        expect(component.masked_configuration).to eq(component.configuration)
      end
    end

    context "when configuration is blank" do
      let(:component) { create(:component, component_type: :a2a_agent, configuration: {}) }

      it "returns the blank configuration" do
        expect(component.masked_configuration).to eq({})
      end
    end
  end
end
