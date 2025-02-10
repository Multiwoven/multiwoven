# frozen_string_literal: true

class SyncAlertMailer < ApplicationMailer
  default from: "AI Squared <ai2-mailer@squared.ai>"

  def sync_success_email
    @alert_attrs = params
    @sync_run_url = "#{sync_run_host}/activate/syncs/#{params[:sync_id]}/run/#{params[:sync_run_id]}"

    mail(to: params[:recipients], subject: "Sync run success")
  end

  def sync_failure_email
    @alert_attrs = params
    @sync_run_url = "#{sync_run_host}/activate/syncs/#{params[:sync_id]}/run/#{params[:sync_run_id]}"

    mail(to: params[:recipients], subject: "Sync run failed")
  end

  def sync_row_failure_email
    @alert_attrs = params
    @sync_run_url = "#{sync_run_host}/activate/syncs/#{params[:sync_id]}/run/#{params[:sync_run_id]}"

    mail(to: params[:recipients], subject: "Sync completed with failed rows")
  end

  private

  def sync_run_host
    host = ENV["UI_HOST"]
    host = "https://#{host}" unless ["https://", "http://"].any? { |protocol| host.start_with? protocol }
    host
  end
end
