# frozen_string_literal: true

class SpendingLimitMailer < ApplicationMailer
  default from: Rails.configuration.x.mail_from

  def threshold_alert_email
    @alert_attrs = params

    mail(
      to: params[:recipients],
      subject: "Spend limit \"#{params[:limit_name]}\" reached #{params[:percentage]}%"
    )
  end
end
