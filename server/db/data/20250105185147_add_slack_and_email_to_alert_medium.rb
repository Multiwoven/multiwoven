# frozen_string_literal: true

class AddSlackAndEmailToAlertMedium < ActiveRecord::Migration[7.1]
  def up
    new_alet_mediums = [
      {
        name: "Email",
        platform: "email"
      },
      {
        name: "Slack",
        platform: "slack"
      }
    ]

    new_alet_mediums.each do |alert_medium|
      AlertMedium.create!(
        name: alert_medium[:name],
        platform: alert_medium[:platform]
      )
    end
  end

  def down
    AlertMedium.where(platform: %w[email slack]).destroy_all
  end
end
