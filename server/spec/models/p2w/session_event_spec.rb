# frozen_string_literal: true

require "rails_helper"

RSpec.describe P2w::SessionEvent do
  let(:workspace) { create(:workspace) }
  let(:workflow) { create(:workflow, workspace:) }
  let(:session) do
    P2w::Session.create!(session_id: SecureRandom.uuid, workflow:,
                         workspace:, status: "running", expires_at: 30.minutes.from_now)
  end

  describe "validations" do
    it "requires sequence, event_type" do
      event = described_class.new(prompt_to_workflow_session_id: session.id)
      event.valid?
      expect(event.errors[:sequence]).not_to be_empty
      expect(event.errors[:event_type]).to include("can't be blank")
    end

    it "enforces unique sequence per session" do
      described_class.create!(prompt_to_workflow_session_id: session.id, sequence: 0, event_type: "test")
      dup = described_class.new(prompt_to_workflow_session_id: session.id, sequence: 0, event_type: "test2")
      expect(dup).not_to be_valid
    end

    it "rejects negative sequence" do
      event = described_class.new(prompt_to_workflow_session_id: session.id, sequence: -1, event_type: "test")
      expect(event).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to session" do
      event = described_class.create!(prompt_to_workflow_session_id: session.id, sequence: 0, event_type: "test")
      expect(event.session).to eq(session)
    end
  end
end
