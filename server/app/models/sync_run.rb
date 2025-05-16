# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class SyncRun < ApplicationRecord
  include AASM
  include Discard::Model

  default_scope -> { kept }

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
  validates :sync_run_type, presence: true

  enum :sync_run_type, %i[general test]
  enum :status, %i[pending started querying queued in_progress success paused failed canceled]

  belongs_to :sync
  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  belongs_to :model
  has_many :sync_records, dependent: :nullify
  has_many :sync_files, dependent: :destroy

  after_initialize :set_defaults, if: :new_record?
  after_discard :perform_post_discard_sync_run
  after_commit :send_status_email, if: :status_changed_to_failure?
  after_commit :queue_sync_alert, if: :saved_change_to_status?
  after_commit :track_usage, if: :saved_change_to_successful_rows?

  scope :active, -> { where(status: %i[pending started querying queued in_progress]) }

  aasm column: :status, whiny_transitions: true do
    state :pending, initial: true
    state :started
    state :querying
    state :queued
    state :in_progress
    state :success
    state :paused
    state :failed
    state :canceled

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

    event :cancel do
      transitions from: %i[pending started querying queued in_progress paused], to: :canceled
    end
  end

  def set_defaults
    self.status ||= self.class.aasm.initial_state.to_s
    self.total_query_rows ||= 0
    self.total_rows ||= 0
    self.successful_rows ||= 0
    self.failed_rows ||= 0
  end

  def perform_post_discard_sync_run
    sync_records.update_all(sync_run_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def update_success
    complete!
    sync.complete!
  end

  def update_failure!
    failed!
    sync.failed!
  end

  def send_status_email
    return unless notification_email_enabled?

    recipients.each do |recipient|
      SyncRunMailer.with(sync_run: self, recipient:).status_email.deliver_now
    end
  end

  def recipients
    if ENV["RECIPIENT_EMAIL"].present?
      [ENV["RECIPIENT_EMAIL"]]
    else
      sync.workspace.workspace_users.admins.map { |workspace_user| workspace_user.user.email }
    end
  end

  def status_changed_to_failure?
    saved_change_to_status? && (status == "failed")
  end

  def update_status_post_workflow
    return if terminal_status?

    update!(finished_at: Time.zone.now)
    update_failure!
  end

  def queue_sync_alert
    SendSyncAlertsJob.perform_later(sync_run_id: id) if send_alert?
  end

  def send_sync_alerts
    workspace.alerts.each do |alert|
      alert.trigger(self)
    end
  end

  def terminal_status?
    success? || failed? || canceled?
  end

  def row_failure_percent
    return 0.0 if total_rows.zero?

    ((failed_rows.to_f / total_rows) * 100).round(2)
  end

  def duration_in_seconds
    now = Time.zone.now
    ((finished_at || now) - (started_at || now)).round
  end

  delegate :active_alerts?, to: :workspace

  private

  def send_alert?
    terminal_status? && active_alerts?
  end

  def track_usage
    active_subscription = workspace.organization.active_subscription
    return unless active_subscription

    # rubocop:disable Rails/SkipsModelValidations
    active_subscription.increment!(:rows_synced, successful_rows)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
# rubocop:enable Metrics/ClassLength
