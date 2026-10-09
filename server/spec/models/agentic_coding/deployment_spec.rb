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
end
