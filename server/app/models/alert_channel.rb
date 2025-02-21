# frozen_string_literal: true

class AlertChannel < ApplicationRecord
  belongs_to :alert
  belongs_to :alert_medium

  def send_success_alert(sync_attrs)
    SyncAlertMailer.with(sync_attrs.merge({ recipients: })).sync_success_email.deliver_now
  end

  def send_failure_alert(sync_attrs)
    SyncAlertMailer.with(sync_attrs.merge({ recipients: })).sync_failure_email.deliver_now
  end

  def send_row_failure_alert(sync_attrs)
    SyncAlertMailer.with(sync_attrs.merge({ recipients: })).sync_row_failure_email.deliver_now
  end

  def recipients
    alert_medium.email? ? email_recipients : slack_recipients
  end

  delegate :platform, to: :alert_medium

  private

  def email_recipients
    ((configuration&.with_indifferent_access&.[](:extra_email_recipients) || []) +
    alert.workspace.verified_admin_user_emails).uniq
  end

  def slack_recipients
    configuration.with_indifferent_access[:slack_email_alias].uniq
  end
end
