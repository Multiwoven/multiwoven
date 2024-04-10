# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def notification_email_enabled?
    Rails.configuration.action_mailer.perform_deliveries &&
      Rails.configuration.action_mailer.smtp_settings[:user_name].present?
  end
end
