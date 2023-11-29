# frozen_string_literal: true

# spec/factories/workspace_users.rb

FactoryBot.define do
  factory :workspace_user do
    association :user
    association :workspace
    role { %w[admin member].sample }
  end
end
