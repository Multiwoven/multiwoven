# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  jti                    :string
#  confirmation_code      :string
#  confirmed_at           :datetime
#  name                   :string
#
# spec/factories/users.rb

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    unique_id { SecureRandom.uuid }
    password {  "testPassword@123" }
    password_confirmation { "testPassword@123" }
    company_name { Faker::Company.name }
    invited_by { nil }
    trait :verified do
      confirmed_at { Time.current }
    end
    trait :invited do
      raw_token = Devise.friendly_token
      after(:build) do |user|
        user.invitation_token = Devise.token_generator.digest(User, :invitation_token, raw_token)
        user.invitation_created_at = Time.current
        user.status = :invited
        user.instance_variable_set(:@raw_invitation_token, raw_token)
      end
    end
    eula_accepted { true }
    eula_accepted_at { Time.current }
    eula_enabled { true }
  end
end
