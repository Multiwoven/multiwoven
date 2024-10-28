# frozen_string_literal: true

FactoryBot.define do
  factory :data_app_session do
    session_id { SecureRandom.hex(10) }
    data_app
    workspace
  end
end
