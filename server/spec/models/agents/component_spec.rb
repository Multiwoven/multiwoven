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
        python_custom: 6
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
<<<<<<< HEAD
=======

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

    context "when component is a2a_agent with top-level api_key" do
      let(:component) do
        create(:component, component_type: :a2a_agent, configuration: {
                 "url" => "https://remote-agent.example.com",
                 "api_key" => "mw-test-secret-key-12345",
                 "agent_card" => { "name" => "Test Agent", "description" => "A test agent" },
                 "skills" => [{ "id" => "s1", "name" => "Skill 1", "description" => "Desc" }]
               })
      end

      it "masks api_key" do
        masked = component.masked_configuration
        expect(masked["api_key"]).to eq("*************")
      end

      it "preserves non-secret fields" do
        masked = component.masked_configuration
        expect(masked["url"]).to eq("https://remote-agent.example.com")
        expect(masked["agent_card"]["name"]).to eq("Test Agent")
        expect(masked["skills"].first["name"]).to eq("Skill 1")
      end

      it "does not mutate the original configuration" do
        component.masked_configuration
        expect(component.configuration["api_key"]).to eq("mw-test-secret-key-12345")
      end
    end

    context "when component is a2a_agent with both api_key and auth_config" do
      let(:component) do
        create(:component, component_type: :a2a_agent, configuration: {
                 "url" => "https://remote-agent.example.com",
                 "api_key" => "top-level-secret",
                 "auth_config" => { "secret" => "nested-secret" },
                 "agent_card" => { "name" => "Agent" }
               })
      end

      it "masks both api_key and auth_config values" do
        masked = component.masked_configuration
        expect(masked["api_key"]).to eq("*************")
        expect(masked["auth_config"]["secret"]).to eq("*************")
      end
    end

    context "when component is a2a_agent with no auth_config and no api_key" do
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

    context "when component is vector_store" do
      let(:api_key) { "sk-openai-secret-key" }
      let(:component) do
        create(:component, component_type: :vector_store, configuration: {
                 "embedding_provider" => "open_ai",
                 "embedding_model" => "text-embedding-3-small",
                 "api_key" => api_key,
                 "limit" => 5,
                 "database" => "connector-uuid-123"
               })
      end

      it "masks api_key" do
        expect(component.masked_configuration["api_key"]).to eq("*************")
      end

      it "preserves non-secret fields" do
        masked = component.masked_configuration
        expect(masked["embedding_provider"]).to eq("open_ai")
        expect(masked["embedding_model"]).to eq("text-embedding-3-small")
        expect(masked["limit"]).to eq(5)
        expect(masked["database"]).to eq("connector-uuid-123")
      end

      it "does not mutate the original configuration" do
        component.masked_configuration
        expect(component.configuration["api_key"]).to eq(api_key)
      end

      context "when api_key is blank" do
        let(:component) do
          create(:component, component_type: :vector_store, configuration: {
                   "embedding_provider" => "open_ai",
                   "embedding_model" => "text-embedding-3-small",
                   "limit" => 5,
                   "database" => "connector-uuid-123"
                 })
        end

        it "returns configuration with api_key absent" do
          masked = component.masked_configuration
          expect(masked).not_to have_key("api_key")
          expect(masked["embedding_provider"]).to eq("open_ai")
        end
      end
    end

    context "when component is not a2a_agent or vector_store" do
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
>>>>>>> 2d3e49530 (fix(CE): added masking configuration for vector store (#1855))
end
