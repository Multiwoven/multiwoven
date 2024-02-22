# frozen_string_literal: true

# == Schema Information
#
# Table name: workspace_users
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  workspace_id :bigint
#  role         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# spec/factories/workspace_users.rb

FactoryBot.define do
  factory :workspace_user do
    association :user
    association :workspace
    role { %w[admin member].sample }
  end
end
