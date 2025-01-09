# frozen_string_literal: true

class Alert < ApplicationRecord
  belongs_to :workspace
  has_many :alert_channels, dependent: :destroy
  accepts_nested_attributes_for :alert_channels

  validates :workspace_id, presence: true
  validates :row_failure_threshold_percent, numericality: { only_integer: true, allow_nil: true }

  def trigger(sync_run)
    alert_channels.each do |alert_channel|
      if send_sucess_alert?(sync_run)
        send_success_alert(alert_common_attributes(sync_run), alert_channel)
      elsif send_failure_alert?(sync_run)
        send_failure_alert(alert_common_attributes(sync_run), alert_channel)
      end

      next unless send_row_failure_alert?(sync_run)

      attrs = {
        failed_rows_count: sync_run.failed_rows,
        total_rows_count: sync_run.total_rows
      }.merge(alert_common_attributes(sync_run))
      send_row_failure_alert(attrs, alert_channel)
    end

    update!(last_run_at: Time.zone.now)
  end

  private

  def send_success_alert(alert_attrs, alert_channel)
    alert_channel.send_success_alert(alert_attrs)
  end

  def send_failure_alert(alert_attrs, alert_channel)
    alert_channel.send_failure_alert(alert_attrs)
  end

  def send_row_failure_alert(alert_attrs, alert_channel)
    alert_channel.send_row_failure_alert(alert_attrs)
  end

  def send_sucess_alert?(sync_run)
    sync_run.success? && alert_sync_success
  end

  def send_failure_alert?(sync_run)
    sync_run.failed? && alert_sync_failure
  end

  def send_row_failure_alert?(sync_run)
    return false unless alert_row_failure

    sync_run.row_failure_percent > row_failure_threshold_percent
  end

  def alert_common_attributes(sync_run)
    @alert_common_attributes ||= {
      name: sync_run.sync.name,
      end_time: sync_run.finished_at,
      duration: sync_run.duration_in_seconds,
      sync_id: sync_run.sync.id,
      sync_run_id: sync_run.id,
      error: sync_run.error
    }
  end
end
