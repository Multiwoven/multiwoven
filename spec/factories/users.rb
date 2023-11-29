# frozen_string_literal: true

# spec/factories/users.rb

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password" }
    password_confirmation { "password" }
    # Add other fields here as required for your model
  end
end
