# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::Workflow, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:components).dependent(:destroy) }
    it { should have_many(:edges).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(draft: 0, published: 1) }
    it {
      should define_enum_for(:trigger_type).with_values(website_chatbot: 0, chat_assistant: 1, scheduled: 2,
                                                        api_trigger: 3)
    }
    it { should define_enum_for(:workflow_type).with_values(runtime: 0, template: 1) }
  end

  describe "scopes" do
    let!(:runtime_workflow) { create(:workflow, workflow_type: 0) }
    let!(:template_workflow) { create(:workflow, workflow_type: 1) }

    describe ".runtime" do
      it "returns workflows as runtime" do
        expect(Agents::Workflow.all).to include(runtime_workflow)
        expect(Agents::Workflow.all).not_to include(template_workflow)
      end
    end

    describe ".template" do
      it "returns workflows as template" do
        expect(Agents::Workflow.unscoped.template).to include(template_workflow)
        expect(Agents::Workflow.unscoped.template).not_to include(runtime_workflow)
      end
    end
  end

  describe "validations" do
    subject { build(:workflow) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:workspace_id).case_insensitive }
    it { should validate_uniqueness_of(:token).allow_nil }
  end

  describe "configuration storage" do
    let(:workflow) { create(:workflow) }

    it "stores configuration as JSON" do
      config_data = { "api_key" => "sk-xxx", "endpoint" => "https://api.example.com" }
      workflow.configuration = config_data
      workflow.save
      workflow.reload
      expect(workflow.configuration).to eq(config_data)
    end
  end

  describe "token generation" do
    it "generates token only when workflow is published" do
      workflow = create(:workflow)
      expect(workflow.token).to be_nil

      workflow.published!
      expect(workflow.token).to be_present
      expect(workflow.token.length).to eq(32) # 16 bytes in hex = 32 characters
    end

    it "does not generate token when workflow is in draft" do
      workflow = create(:workflow)
      expect(workflow.token).to be_nil

      workflow.save
      expect(workflow.token).to be_nil
    end

    it "generates unique tokens for different workflows" do
      workflow1 = create(:workflow)
      workflow2 = create(:workflow)

      workflow1.published!
      workflow2.published!

      expect(workflow1.token).to be_present
      expect(workflow2.token).to be_present
      expect(workflow1.token).not_to eq(workflow2.token)
    end
  end
end
