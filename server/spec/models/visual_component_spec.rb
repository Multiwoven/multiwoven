# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisualComponent, type: :model do
  it { should validate_presence_of(:workspace_id) }
  it { should validate_presence_of(:component_type) }
  it { should validate_presence_of(:configurable) }
  it { should validate_presence_of(:data_app_id) }

  it {
    should define_enum_for(:component_type)
      .with_values(doughnut: 0, bar: 1, data_table: 2, visual_text: 3, custom: 4, chat_bot: 5)
  }

  it { should belong_to(:workspace) }
  it { should belong_to(:data_app) }
  it { should belong_to(:configurable) }
  it { should have_many(:feedbacks).dependent(:destroy) }
  it { should have_many(:chat_messages).dependent(:destroy) }
  it { should have_many(:message_feedbacks).dependent(:destroy) }

  describe "#model" do
    let(:model) { create(:model) }
    let(:workflow) { create(:workflow) }

    context "when configurable is a Model" do
      let(:visual_component) { create(:visual_component, configurable: model) }

      it "returns the model" do
        expect(visual_component.model).to eq(model)
      end

      it "returns the same model instance" do
        expect(visual_component.model.object_id).to eq(model.object_id)
      end
    end

    context "when configurable is not a Model" do
      let(:visual_component) { create(:visual_component, configurable: workflow) }

      it "returns nil" do
        expect(visual_component.model).to be_nil
      end
    end

    context "when configurable is nil" do
      let(:visual_component) { build(:visual_component, configurable: nil) }

      it "returns nil" do
        expect(visual_component.model).to be_nil
      end
    end
  end

  describe "#workflow" do
    let(:model) { create(:model) }
    let(:workflow) { create(:workflow) }

    context "when configurable is a Workflow" do
      let(:visual_component) { create(:visual_component, configurable: workflow) }

      it "returns the workflow" do
        expect(visual_component.workflow).to eq(workflow)
      end

      it "returns the same workflow instance" do
        expect(visual_component.workflow.object_id).to eq(workflow.object_id)
      end
    end

    context "when configurable is not a Workflow" do
      let(:visual_component) { create(:visual_component, configurable: model) }

      it "returns nil" do
        expect(visual_component.workflow).to be_nil
      end
    end

    context "when configurable is nil" do
      let(:visual_component) { build(:visual_component, configurable: nil) }

      it "returns nil" do
        expect(visual_component.workflow).to be_nil
      end
    end
  end
end
