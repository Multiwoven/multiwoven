# frozen_string_literal: true

class SyncFile < ApplicationRecord
  belongs_to :workspace
  belongs_to :sync

  validates :file_name, presence: true
  validates :file_path, presence: true
  validates :workspace_id, presence: true
  validates :sync_id, presence: true
  validates :sync_run_id, presence: true

  enum status: {
    pending: 0,
    progress: 1,
    completed: 2,
    failed: 3,
    skipped: 4
  }

  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :pending
  end
end
