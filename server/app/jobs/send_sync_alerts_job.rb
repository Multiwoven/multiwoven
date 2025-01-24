# frozen_string_literal: true

class SendSyncAlertsJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :solid_queue

  def perform(*args)
    sync_run = SyncRun.find(args[:sync_id])
    sync_run&.send_sync_alerts
  end
end
