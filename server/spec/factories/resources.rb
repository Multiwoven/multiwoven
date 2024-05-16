# frozen_string_literal: true

# == Schema Information
#
# Table name: resources
#
#  id                :bigint           not null, primary key
#  resources_name    :string
#  permissions       :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :resource do
    sequence(:resources_name) { |n| "Resource #{n}" }
    permissions { %w[read write] }
  end
end
