# frozen_string_literal: true

FactoryBot.define do
  factory :alert_channel do
    association :alert

    trait :email do
      platform { "email" }
      configuration { { extra_email_recipients: ["user1@example.com", "user2@example.com"] } }
    end

    trait :slack do
      platform { "slack" }
      configuration { { slack_email_alias: ["slackemailtemplate@slack.com"] } }
    end
  end
end
