# frozen_string_literal: true

require "rails_helper"

RSpec.describe P2w::Session do
  let(:workspace) { create(:workspace) }
  let(:workflow) { create(:workflow, workspace:) }

  describe "validations" do
    it "requires session_id and expires_at" do
      session = described_class.new
      session.valid?
      expect(session.errors[:session_id]).to include("can't be blank")
      expect(session.errors[:expires_at]).to include("can't be blank")
    end

    it "enforces unique session_id" do
      uid = SecureRandom.uuid
      described_class.create!(session_id: uid, workflow:, workspace:,
                              expires_at: 30.minutes.from_now)
      dup = described_class.new(session_id: uid, workflow:, workspace:,
                                expires_at: 30.minutes.from_now)
      expect(dup).not_to be_valid
      expect(dup.errors[:session_id]).to include("has already been taken")
    end

    it "validates status inclusion" do
      session = described_class.new(status: "invalid_status")
      session.valid?
      expect(session.errors[:status]).to include("is not included in the list")
    end
  end

  describe "scopes" do
    let!(:running_session) do
      described_class.create!(session_id: SecureRandom.uuid, workflow:, workspace:,
                              status: "running", expires_at: 30.minutes.from_now)
    end
    let!(:completed_session) do
      described_class.create!(session_id: SecureRandom.uuid, workflow:, workspace:,
                              status: "completed", expires_at: 30.minutes.from_now)
    end
    let!(:expired_session) do
      described_class.create!(session_id: SecureRandom.uuid, workflow:, workspace:,
                              status: "running", expires_at: 1.minute.ago)
    end

    it ".active returns running and clarification_pending" do
      expect(described_class.active).to include(running_session)
      expect(described_class.active).not_to include(completed_session)
    end

    it ".not_expired excludes expired sessions" do
      expect(described_class.not_expired).to include(running_session)
      expect(described_class.not_expired).not_to include(expired_session)
    end
  end

  describe "helper methods" do
    let(:session) do
      described_class.new(status: "running", expires_at: 30.minutes.from_now)
    end

    it "#terminal? returns true for terminal statuses" do
      expect(described_class.new(status: "completed")).to be_terminal
      expect(described_class.new(status: "failed")).to be_terminal
      expect(described_class.new(status: "running")).not_to be_terminal
    end

    it "#expired? checks expires_at" do
      expect(described_class.new(expires_at: 1.minute.ago)).to be_expired
      expect(described_class.new(expires_at: 30.minutes.from_now)).not_to be_expired
    end

    it "#replayable? returns true when not expired" do
      expect(described_class.new(expires_at: 30.minutes.from_now)).to be_replayable
      expect(described_class.new(expires_at: 1.minute.ago)).not_to be_replayable
    end

    it "#accepts_clarification? requires clarification_pending and not expired" do
      session = described_class.new(status: "clarification_pending", expires_at: 30.minutes.from_now)
      expect(session.accepts_clarification?).to be true

      session.status = "running"
      expect(session.accepts_clarification?).to be false
    end
  end
end
