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
end
