# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  def invitation_instructions(record, token, opts = {})
    @workspace = opts[:workspace]
    @role = opts[:role]
    @token = token
    super
  end
end
