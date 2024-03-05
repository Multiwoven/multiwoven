# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRecord, type: :model do
  it { should validate_presence_of(:sync_id) }
  it { should validate_presence_of(:sync_run_id) }
  it { should validate_presence_of(:record) }
  it { should validate_presence_of(:fingerprint) }
  it { should validate_presence_of(:action) }
  it { should validate_presence_of(:primary_key) }

  it { should belong_to(:sync) }
  it { should belong_to(:sync_run) }

  describe "validations" do
    let!(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
    let!(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let!(:sync) do
      create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:)
    end
    let!(:sync_run) { create(:sync_run, sync:) }
    let!(:existing_record) do
      create(:sync_record, sync:, sync_run:, fingerprint: "unique_fingerprint", primary_key: "key1")
    end

    it "validates uniqueness of fingerprint and sync_id combination" do
      new_record = build(:sync_record, sync:, sync_run:, fingerprint: existing_record.fingerprint)
      expect do
        new_record.save!
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "validates uniqueness of sync_id and primary_key combination" do
      new_record = build(:sync_record, sync:, sync_run:, primary_key: existing_record.primary_key)
      expect do
        new_record.save!
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
