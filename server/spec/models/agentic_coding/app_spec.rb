# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::App, type: :model do
  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:status) }
    it { should belong_to(:workspace) }
    it { should belong_to(:user) }
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:prompts).dependent(:destroy) }
    it { should have_many(:deployments).dependent(:destroy) }
    it { should define_enum_for(:status).with_values(draft: 0, published: 1, archived: 2) }
  end

  describe "default status" do
    let(:app) { described_class.new }

    it "sets default status" do
      expect(app.status).to eq("draft")
    end
  end
end
