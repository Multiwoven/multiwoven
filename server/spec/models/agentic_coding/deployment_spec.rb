# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::Deployment, type: :model do
  context "validations" do
    it { should validate_presence_of(:status) }
    it { should belong_to(:workspace) }
    it { should belong_to(:agentic_coding_app).class_name("AgenticCoding::App") }
    it { should belong_to(:agentic_coding_session).class_name("AgenticCoding::Session") }
    it { should define_enum_for(:status).with_values(pending: 0, running: 1, succeeded: 2, failed: 3) }
  end

  describe "default status" do
    let(:deployment) { described_class.new }

    it "sets default status" do
      expect(deployment.status).to eq("pending")
    end
  end

  describe ".with_neon_timestamp" do
    let!(:with_timestamp) { create(:agentic_coding_deployment, neon_deployed_at: 1.hour.ago) }
    let!(:without_timestamp) { create(:agentic_coding_deployment, neon_deployed_at: nil) }

    it "returns only deployments that have neon_deployed_at set" do
      expect(described_class.with_neon_timestamp).to include(with_timestamp)
      expect(described_class.with_neon_timestamp).not_to include(without_timestamp)
    end
  end

  describe "neon_deployed_at column" do
    it "persists a datetime value" do
      ts = Time.zone.now.utc.round
      deployment = create(:agentic_coding_deployment, neon_deployed_at: ts)
      expect(deployment.reload.neon_deployed_at.utc.to_i).to eq(ts.to_i)
    end

    it "defaults to nil when not set" do
      deployment = create(:agentic_coding_deployment)
      expect(deployment.neon_deployed_at).to be_nil
    end
  end
end
