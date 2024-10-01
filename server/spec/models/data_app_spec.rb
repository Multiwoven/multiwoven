# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataApp, type: :model do
  subject { create(:data_app) }

  context "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:data_app_token) }
    it { should define_enum_for(:status).with_values(inactive: 0, active: 1, draft: 2) }
    it { should belong_to(:workspace) }
    it { should have_many(:visual_components).dependent(:destroy) }
    it { should have_many(:models).through(:visual_components) }
  end

  describe "#set_default_status" do
    let(:data_app) { DataApp.new }

    it "sets default status" do
      expect(data_app.status).to eq("draft")
    end
  end

  describe "#generate_data_app_token" do
    let(:workspace) { create(:workspace) }
    let(:data_app) { create(:data_app, workspace:) }

    it "generates a unique token before creation" do
      expect(data_app.data_app_token).to be_present
    end

    it "ensures the token is unique" do
      second_data_app = create(:data_app, workspace:)
      expect(second_data_app.data_app_token).not_to eq(data_app.data_app_token)
    end

    it "should raise an error if token is not unique" do
      allow(DataApp).to receive(:exists?).and_return(true, false)

      unique_token = data_app.send(:generate_unique_token)
      expect(unique_token).to be_present
      expect(unique_token).not_to eq(data_app.data_app_token)
    end
  end
end
