# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::Prompt, type: :model do
  context "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:status) }
    it { should belong_to(:agentic_coding_app).class_name("AgenticCoding::App") }
    it { should belong_to(:agentic_coding_session).class_name("AgenticCoding::Session") }
    it { should define_enum_for(:role).with_values(user: 0, assistant: 1) }
    it { should define_enum_for(:status).with_values(queued: 0, running: 1, completed: 2, failed: 3) }
  end

  describe "default status" do
    let(:prompt) { described_class.new }

    it "sets default status" do
      expect(prompt.status).to eq("queued")
    end
  end
end
