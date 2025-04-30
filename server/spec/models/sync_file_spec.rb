# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncFile, type: :model do
  it { should belong_to(:workspace) }
  it { should belong_to(:sync) }

  it { should validate_presence_of(:file_name) }
  it { should validate_presence_of(:file_path) }
  it { should validate_presence_of(:workspace_id) }
  it { should validate_presence_of(:sync_id) }
  it { should validate_presence_of(:sync_run_id) }

  it do
    should define_enum_for(:status).with_values(
      pending: 0,
      progress: 1,
      completed: 2,
      failed: 3,
      skipped: 4
    )
  end

  describe "default values" do
    it "sets status to pending by default" do
      sync_file = described_class.new
      expect(sync_file.status).to eq("pending")
    end
  end
end
