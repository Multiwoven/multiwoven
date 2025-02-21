# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataAppSession, type: :model do
  let(:workspace) { create(:workspace) }
  let(:data_app) { create(:data_app, workspace:) }

  describe "associations" do
    it { should belong_to(:data_app) }
    it { should belong_to(:workspace) }
  end

  describe "validations" do
    subject { build(:data_app_session, workspace:, data_app:) }

    it { should validate_presence_of(:session_id) }
    it { should validate_uniqueness_of(:session_id) }
    it { should validate_presence_of(:data_app_id) }
    it { should validate_presence_of(:workspace_id) }
  end

  describe "callbacks" do
    it "sets the start_time and end_time before creation" do
      session = DataAppSession.new(workspace:, data_app:, session_id: "session_abc")
      session.save
      expect(session.start_time).to be_present
      expect(session.end_time).to eq(session.start_time + 10.minutes)
    end
  end

  describe ".active scope" do
    it "returns active sessions" do
      active_session = create(:data_app_session, workspace:, data_app:)
      expired_session = create(:data_app_session, workspace:, data_app:)
      expired_session.update(end_time: 1.minute.ago)
      expect(DataAppSession.active).to include(active_session)
      expect(DataAppSession.active).not_to include(expired_session)
    end
  end

  describe "#expired?" do
    it "returns true if the session is expired" do
      session = create(:data_app_session, workspace:, data_app:)
      session.update(end_time: 1.minute.ago)
      expect(session.expired?).to be true
    end

    it "returns false if the session is active" do
      session = create(:data_app_session, workspace:, data_app:)
      expect(session.expired?).to be false
    end
  end

  describe "#track_usage" do
    let(:organization) { create(:organization) }
    let(:workspace) { create(:workspace, organization:) }
    let(:plan) { create(:billing_plan) }
    let(:subscription) { create(:billing_subscription, organization:, plan:, status: 1) }
    let!(:data_app) { create(:data_app, workspace:, visual_components_count: 1) }
    let(:data_app_session) { build(:data_app_session, workspace:, data_app:) }

    context "when organization has an active subscription" do
      before do
        allow(workspace.organization).to receive(:active_subscription).and_return(subscription)
      end

      it "increments the data app session count on the subscription" do
        expect { data_app_session.save }.to change { subscription.data_app_sessions }.by(1)
      end
    end

    context "when organization has no active subscription" do
      before do
        allow(workspace.organization).to receive(:active_subscription).and_return(nil)
      end

      it "does not increment any data app session count" do
        expect(subscription).not_to receive(:increment!)
        data_app_session.save
      end
    end
  end
end
