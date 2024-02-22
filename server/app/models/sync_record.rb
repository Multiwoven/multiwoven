# frozen_string_literal: true

class SyncRecord < ApplicationRecord
  validates :sync_id, presence: true
  validates :sync_run_id, presence: true
  validates :record, presence: true
  validates :fingerprint, presence: true
  validates :action, presence: true
  validates :primary_key, presence: true

  enum :action, %i[destination_insert destination_update]
  enum :status, %i[pending success failed]

  belongs_to :sync
  belongs_to :sync_run
end
