# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataApp, type: :model do
  subject { create(:data_app) }

  context "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:data_app_token) }
    it { should define_enum_for(:status).with_values(inactive: 0, active: 1, draft: 2) }
    it { should define_enum_for(:rendering_type).with_values(embed: 0, no_code: 1, assistant: 2) }
    it { should belong_to(:workspace) }
    it { should have_many(:visual_components).dependent(:destroy) }
    it { should have_many(:models).through(:visual_components) }
    it { should have_many(:data_app_sessions).dependent(:destroy) }
    it { should have_many(:feedbacks).through(:visual_components) }
    it { should have_many(:chat_messages).through(:visual_components) }
    it { should have_many(:message_feedbacks).through(:visual_components) }

    it "has a counter cache for sessions and feedbacks" do
      data_app = create(:data_app)

      expect do
        create(:data_app_session, data_app:)
      end.to change { data_app.reload.data_app_sessions_count }.by(1)

      expect do
        create(:feedback, visual_component: data_app.visual_components.first)
      end.to change { data_app.reload.feedbacks_count }.by(1)

      expect do
        create(:chat_message, visual_component: data_app.visual_components.first)
      end.to change { data_app.reload.chat_messages_count }.by(1)

      expect do
        create(:message_feedback, visual_component: data_app.visual_components.first)
      end.to change { data_app.reload.message_feedbacks_count }.by(1)

      expect do
        data_app.data_app_sessions.first.destroy
      end.to change { data_app.reload.data_app_sessions_count }.by(-1)

      expect do
        data_app.visual_components.first.feedbacks.first.destroy
      end.to change { data_app.reload.feedbacks_count }.by(-1)

      expect do
        data_app.visual_components.first.chat_messages.first.destroy
      end.to change { data_app.reload.chat_messages_count }.by(-1)

      expect do
        data_app.visual_components.first.message_feedbacks.first.destroy
      end.to change { data_app.reload.message_feedbacks_count }.by(-1)
    end
  end

  describe "#set_default_status" do
    let(:data_app) { DataApp.new }

    it "sets default status" do
      expect(data_app.status).to eq("draft")
    end
  end

  describe "#generate_data_app_token" do
    let(:workspace) { create(:workspace) }
    let(:data_app) { create(:data_app, workspace:) }

    it "generates a unique token before creation" do
      expect(data_app.data_app_token).to be_present
    end

    it "ensures the token is unique" do
      second_data_app = create(:data_app, workspace:)
      expect(second_data_app.data_app_token).not_to eq(data_app.data_app_token)
    end

    it "should raise an error if token is not unique" do
      allow(DataApp).to receive(:exists?).and_return(true, false)

      unique_token = data_app.send(:generate_unique_token)
      expect(unique_token).to be_present
      expect(unique_token).not_to eq(data_app.data_app_token)
    end
  end
end
