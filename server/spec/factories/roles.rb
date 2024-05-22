# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id                :bigint           not null, primary key
#  role_name         :string
#  role_desc         :string
#  policies          :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :role do
    sequence(:role_name) { |n| "Role #{n}" }
    role_desc { "Description for #{role_name}" }
    policies { { "action" => "allow", "permissions" => ["read"], "resources" => %w[resource1 resource2] } }
  end
end
