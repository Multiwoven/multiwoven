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
class Role < ApplicationRecord
  include Utils::Constants

  validates :role_name, presence: true
  validates :policies, presence: true
<<<<<<< HEAD
=======

  enum role_type: { custom: 0, system: 1 }

  belongs_to :organization, optional: true

  # rubocop:disable Layout/LineLength
  scope :organization_roles, lambda { |org_id|
                               where("organization_id IS NULL AND role_type = 1 OR organization_id = ? AND role_type = 0", org_id)
                             }
  # rubocop:enable Layout/LineLength

  def grouped_policies
    raw_policies = policies.deep_dup
    raw_permissions = raw_policies["permissions"]

    updated_permissions = raw_permissions.map do |resource_key, permission|
      group = RESOURCE_GROUP_MAPPING.find do |_group_name, details|
        details[:resources].include?(resource_key.to_sym)
      end

      if group
        group_name, details = group
        [resource_key, permission.merge(group: { name: group_name, description: details[:description] })]
      else
        [resource_key, permission]
      end
    end.to_h

    raw_policies["permissions"] = updated_permissions
    raw_policies
  end
>>>>>>> 52e4e72b (feat(CE): add group meta to resource (#872))
end
