# frozen_string_literal: true

class SyncRun < ApplicationRecord
  include AASM

  validates :sync_id, presence: true
  validates :status, presence: true
  validates :total_query_rows, presence: true
  validates :total_rows, presence: true
  validates :successful_rows, presence: true
  validates :failed_rows, presence: true
  validates :workspace_id, presence: true
  validates :source_id, presence: true
  validates :destination_id, presence: true
  validates :model_id, presence: true

  enum :status, %i[pending started querying queued in_progress success paused failed]

  belongs_to :sync
  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  belongs_to :model
  has_many :sync_records, dependent: :nullify

  after_initialize :set_defaults, if: :new_record?

  aasm column: :status, whiny_transitions: true do # rubocop:disable Metrics/BlockLength
    state :pending, initial: true
    state :started
    state :querying
    state :queued
    state :in_progress
    state :success
    state :paused
    state :failed

    # Most states, including "started," allow for a retry by transitioning back to the same state
    # example:
    # If a temporal activity fails while in the "Started" state, a temporal retry may be initiated.
    # For this retry to occur, the activity transitions from the "Started" state back to "Started," indicating
    # a reattempt of the operation.
    event :start do
      transitions from: %i[pending started querying], to: :started
    end

    event :query do
      transitions from: :started, to: :querying
    end

    event :queue do
      transitions from: :querying, to: :queued
    end

    event :progress do
      transitions from: %i[queued paused in_progress], to: :in_progress
    end

    event :pause do
      transitions from: :in_progress, to: :paused
    end

    event :complete do
      transitions from: :in_progress, to: :success
    end

    event :abort do
      transitions from: %i[pending started querying queued in_progress paused failed], to: :failed
    end
  end

  def set_defaults
    self.status ||= self.class.aasm.initial_state.to_s
    self.total_query_rows ||= 0
    self.total_rows ||= 0
    self.successful_rows ||= 0
    self.failed_rows ||= 0
  end

  def update_success
    complete!
    sync.complete!
  end
end
