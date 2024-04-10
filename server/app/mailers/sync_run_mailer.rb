# frozen_string_literal: true

class SyncRunMailer < ApplicationMailer
  default from: Rails.configuration.x.mail_from

  def status_email
    @sync_run = params[:sync_run]
    @sync = @sync_run.sync
    @sync_status = @sync_run.status
    @source_connector_name = @sync_run.sync.source.name
    @destination_connector_name = @sync_run.sync.destination.name
    host = Rails.configuration.action_mailer.default_url_options[:host]
    @sync_run_url = "#{host}/activate/syncs/#{@sync.id}/run/#{@sync_run.id}"
    mail(to: params[:recipient], subject: "Sync run status update") do |format|
      format.html { render layout: false }
    end
  end
end
