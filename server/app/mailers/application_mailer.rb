# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@multiwoven.com"
  layout "mailer"
end
