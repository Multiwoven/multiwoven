# frozen_string_literal: true

FactoryBot.define do
  factory :p2w_session, class: "P2w::Session" do
    workspace
    workflow
    session_id { SecureRandom.uuid }
    status { "running" }
    expires_at { 30.minutes.from_now }
    state { {} }
  end
end
