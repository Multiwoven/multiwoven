# frozen_string_literal: true

class WorkspaceUserMailer < ApplicationMailer
  default from: Rails.configuration.x.mail_from

  def send_invitation_email(user, workspace)
    @user = user
    @workspace = workspace
    mail(to: @user.email, subject: "You have been invited to join a workspace!")
  end
end
