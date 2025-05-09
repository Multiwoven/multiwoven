# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feedback, type: :model do
  describe "associations" do
    it { should belong_to(:data_app) }
    it { should belong_to(:visual_component) }
    it { should belong_to(:model) }
    it { should belong_to(:workspace) }
  end

  describe "validations" do
    it { should validate_presence_of(:data_app_id) }
    it { should validate_presence_of(:visual_component_id) }
    it { should validate_presence_of(:model_id) }
    it { should validate_presence_of(:feedback_type) }
  end

  describe "enum" do
    it {
      should define_enum_for(:feedback_type)
        .with_values(thumbs: 0, scale_input: 1, text_input: 2, dropdown: 3, multiple_choice: 4)
    }

    it do
      should define_enum_for(:reaction).with_values(
        negative: -99,
        positive: 99,
        scale_one: 1,
        scale_two: 2,
        scale_three: 3,
        scale_four: 4,
        scale_five: 5,
        scale_six: 6,
        scale_seven: 7,
        scale_eight: 8,
        scale_nine: 9,
        scale_ten: 10
      )
    end
  end

  describe "#track_usage" do
    let(:organization) { create(:organization) }
    let(:workspace) { create(:workspace, organization:) }
    let(:plan) { create(:billing_plan) }
    let(:subscription) { create(:billing_subscription, organization:, plan:, status: 1) }
    let(:feedback) { build(:feedback, workspace:) }

    context "when organization has an active subscription" do
      before do
        allow(workspace.organization).to receive(:active_subscription).and_return(subscription)
      end

      it "increments the feedback count on the subscription" do
        expect { feedback.save }.to change { subscription.feedback_count }.by(1)
      end
    end

    context "when organization has no active subscription" do
      before do
        allow(workspace.organization).to receive(:active_subscription).and_return(nil)
      end

      it "does not increment any feedback count" do
        expect(subscription).not_to receive(:increment!)
        feedback.save
      end
    end
  end

  describe ":tags of type acts_on_taggable_on" do
    let(:organization) { create(:organization) }
    let(:workspace) { create(:workspace, organization:) }
    let(:feedback) { build(:feedback, workspace:) }

    it "does not exist in model class" do
      expect(Feedback.column_names.include?(:tags)).to be_falsey
    end
    it "does not exist in model instance" do
      expect(feedback.has_attribute?(:tags)).to be_falsey
    end
    it "exists in model instance as tag_list" do
      expect(feedback.has_attribute?(:tag_list)).to be_truthy
    end
  end
end
