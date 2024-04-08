class SyncRunMailer < ApplicationMailer
  default from: ENV['SMTP_USERNAME']

  def status_email
    @sync_run = params[:sync_run]
    @sync_status = @sync_run.status
    mail(to: params[:recipient], subject: "Sync run status update")
  end
end
