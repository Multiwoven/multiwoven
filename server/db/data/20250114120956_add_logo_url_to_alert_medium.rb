# frozen_string_literal: true

class AddLogoUrlToAlertMedium < ActiveRecord::Migration[7.1]
  def up
    slack_medium = AlertMedium.where(platform: "slack").last
    email_medium = AlertMedium.where(platform: "email").last

    slack_medium.update!(logo: "https://res.cloudinary.com/dspflukeu/image/upload/v1736851449/AIS/static-assets/images/slack_qmfgj4.png")
    email_medium.update!(logo: "https://res.cloudinary.com/dspflukeu/image/upload/v1736851449/AIS/static-assets/images/email_rltvq6.png")
  end
end
