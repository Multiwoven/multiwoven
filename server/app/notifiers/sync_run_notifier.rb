# To deliver this notification:
#
# SyncRunNotifier.with(record: @post, message: "New post").deliver(User.all)

class SyncRunNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "SyncRunMailer"
    config.method = "status_email"
    config.enqueue = false
  end

  required_param :sync_run, :recipient
end
