# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::WorkflowSession, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workflow).class_name("Agents::Workflow") }
    it { is_expected.to belong_to(:workspace) }
    it { is_expected.to have_many(:chat_messages).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:workflow_session) }

    it { is_expected.to validate_presence_of(:session_id) }
    it { is_expected.to validate_uniqueness_of(:session_id) }
    it { is_expected.to validate_presence_of(:workflow_id) }
    it { is_expected.to validate_presence_of(:workspace_id) }
  end

  describe "callbacks" do
    describe "before_create :set_times" do
      it "sets start_time to current time" do
        freeze_time do
          session = create(:workflow_session)
          expect(session.start_time).to be_within(1.second).of(Time.zone.now)
        end
      end

      it "sets end_time to start_time plus default session length" do
        freeze_time do
          session = create(:workflow_session)
          default_minutes = (ENV["WORKFLOW_SESSION_LENGTH_MINUTES"] || 10).to_i
          expect(session.end_time).to be_within(1.second).of(session.start_time + default_minutes.minutes)
        end
      end

      context "when WORKFLOW_SESSION_LENGTH_MINUTES is set" do
        it "uses the configured session length" do
          freeze_time do
            stub_const("ENV", ENV.to_h.merge("WORKFLOW_SESSION_LENGTH_MINUTES" => "30"))
            session = create(:workflow_session)
            expect(session.end_time).to be_within(1.second).of(session.start_time + 30.minutes)
          end
        end
      end
    end
  end

  describe ".active" do
    let(:workflow) { create(:workflow) }
    let(:workspace) { workflow.workspace }

    it "includes sessions with end_time in the future" do
      active_session = create(:workflow_session, workflow:, workspace:)
      expect(active_session.end_time).to be > Time.zone.now
      expect(described_class.active).to include(active_session)
    end

    it "includes sessions with nil end_time" do
      session = create(:workflow_session, workflow:, workspace:)
      session.update!(end_time: nil)
      expect(described_class.active).to include(session)
    end

    it "excludes sessions with end_time in the past" do
      expired_session = create(:workflow_session, workflow:, workspace:)
      expired_session.update!(end_time: 30.minutes.ago)
      expect(described_class.active).not_to include(expired_session)
    end
  end

  describe "#expired?" do
    let(:workflow) { create(:workflow) }
    let(:workspace) { workflow.workspace }

    it "returns false when end_time is in the future" do
      session = create(:workflow_session, workflow:, workspace:)
      expect(session.expired?).to be false
    end

    it "returns false when end_time is nil" do
      session = create(:workflow_session, workflow:, workspace:)
      session.update!(end_time: nil)
      expect(session.expired?).to be false
    end

    it "returns true when end_time is in the past" do
      session = create(:workflow_session, workflow:, workspace:)
      session.update!(end_time: 1.minute.ago)
      expect(session.expired?).to be true
    end

    it "returns true when end_time is exactly now" do
      freeze_time do
        session = create(:workflow_session, workflow:, workspace:)
        session.update!(end_time: Time.zone.now)
        expect(session.expired?).to be true
      end
    end
  end

  describe "counter_culture" do
    let(:workflow) { create(:workflow) }

    it "increments workflow workflow_sessions_count on create" do
      expect do
        create(:workflow_session, workflow:)
      end.to change { workflow.reload.workflow_sessions_count }.by(1)
    end

    it "decrements workflow workflow_sessions_count on destroy" do
      session = create(:workflow_session, workflow:)
      expect do
        session.destroy
      end.to change { workflow.reload.workflow_sessions_count }.by(-1)
    end
  end

  describe "chat_messages" do
    let(:workflow_session) { create(:workflow_session) }

    it "destroys associated chat_messages when session is destroyed" do
      msg = create(:chat_message, :workflow_session, session: workflow_session,
                                                     workspace: workflow_session.workspace,
                                                     workflow: workflow_session.workflow)
      expect { workflow_session.destroy }.to change(ChatMessage, :count).by(-1)
      expect(ChatMessage.exists?(msg.id)).to be false
    end
  end
end
