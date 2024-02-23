# frozen_string_literal: true

class SyncRun < ApplicationRecord
  validates :sync_id, presence: true
  validates :status, presence: true
  validates :started_at, presence: true
  validates :finished_at, presence: true
  validates :total_rows, presence: true
  validates :successful_rows, presence: true
  validates :failed_rows, presence: true
  validates :workspace_id, presence: true
  validates :source_id, presence: true
  validates :destination_id, presence: true
  validates :model_id, presence: true

  enum :status, %i[pending in_progress success failed incomplete]

  belongs_to :sync
  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  belongs_to :model
  has_many :sync_records, dependent: :nullify

  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.status ||= "pending"
    self.total_rows ||= 0
    self.successful_rows ||= 0
    self.failed_rows ||= 0
    self.started_at ||= Time.zone.now
    self.finished_at ||= Time.zone.now
  end
end
