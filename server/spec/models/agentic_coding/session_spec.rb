# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::Session, type: :model do
  context "validations" do
    it { should validate_presence_of(:status) }
    it { should belong_to(:workspace) }
    it { should belong_to(:user) }
    it { should belong_to(:agentic_coding_app).class_name("AgenticCoding::App") }
    it { should have_many(:prompts).dependent(:destroy) }
    it { should have_many(:deployments).dependent(:destroy) }
    it { should define_enum_for(:status).with_values(active: 0, paused: 1, ended: 2) }
  end

  describe "default status" do
    let(:session) { described_class.new }

    it "sets default status" do
      expect(session.status).to eq("active")
    end
  end
end
