# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataApp, type: :model do
  it { should validate_presence_of(:workspace_id) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:name) }

  it { should define_enum_for(:status).with_values(inactive: 0, active: 1, draft: 2) }

  it { should belong_to(:workspace) }
  it { should have_many(:visual_components).dependent(:destroy) }
  it { should have_many(:models).through(:visual_components) }

  describe "#set_default_status" do
    let(:data_app) { DataApp.new }

    it "sets default status" do
      expect(data_app.status).to eq("draft")
    end
  end
end
