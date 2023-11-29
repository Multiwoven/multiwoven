# frozen_string_literal: true

# app/mailers/user_mailer.rb

class UserMailer < ApplicationMailer
  default from: Rails.configuration.x.mail_from

  def send_confirmation_code(user)
    @user = user
    @confirmation_code = user.confirmation_code
    mail(to: @user.email, subject: "Your Confirmation Code")
  end
end
