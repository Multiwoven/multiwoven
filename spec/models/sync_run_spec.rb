# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRun, type: :model do
  it { should validate_presence_of(:sync_id) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:started_at) }
  it { should validate_presence_of(:finished_at) }
  it { should validate_presence_of(:total_rows) }
  it { should validate_presence_of(:successful_rows) }
  it { should validate_presence_of(:failed_rows) }
  it { should validate_presence_of(:workspace_id) }
  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:destination_id) }
  it { should validate_presence_of(:model_id) }

  it { should belong_to(:sync) }
  it { should have_many(:sync_records) }

  describe "enum for status" do
    it { should define_enum_for(:status).with_values(%i[pending in_progress success failed incomplete]) }
  end
end
