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
  validates :role_name, uniqueness: {
    scope: :organization_id,
    message: "A role with this name already exists."
  }, if: -> { organization.present? }
  validates :policies, presence: true
  validate :prevent_reserved_role_names, if: -> { custom? }

  enum role_type: { custom: 0, system: 1 }

  belongs_to :organization, optional: true

  # rubocop:disable Layout/LineLength
  scope :organization_roles, lambda { |org_id|
                               where("organization_id IS NULL AND role_type = 1 OR organization_id = ? AND role_type = 0", org_id)
                             }
  # rubocop:enable Layout/LineLength

  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :workspace_users
  # rubocop:enable Rails/HasManyOrHasOneDependent

  before_destroy :check_role_assigned_to_users

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

  def permission_count
    {
      read: policies["permissions"].count { |_resource, perms| perms["read"] == true },
      create: policies["permissions"].count { |_resource, perms| perms["create"] == true },
      delete: policies["permissions"].count { |_resource, perms| perms["delete"] == true },
      update: policies["permissions"].count { |_resource, perms| perms["update"] == true }
    }
  end

  def group_permissions_count
    permission_types = %i[read create delete update]
    group_permissions = permission_types.index_with { |_type| 0 }
    groups = group_resources_by_name

    count_group_permissions(groups, permission_types, group_permissions)
  end

  def prevent_reserved_role_names
    reserved_names = %w[admin member viewer]
    return unless reserved_names.include?(role_name.to_s.downcase)

    errors.add(:role_name, "is a reserved name")
  end

  private

  def check_role_assigned_to_users
    return unless workspace_users.exists?

    errors.add(
      :base,
      "You cannot delete #{role_name} role as it is assigned to team members. " \
      "Please reassign or remove them before deleting this role."
    )
    throw(:abort)
  end

  def group_resources_by_name
    grouped_policies["permissions"].each_with_object({}) do |(_, permission), acc|
      next unless permission[:group]

      group_name = permission[:group][:name]
      acc[group_name] ||= []
      acc[group_name] << permission
    end
  end

  def count_group_permissions(groups, permission_types, group_permissions)
    groups.each_value do |permissions|
      permission_types.each do |type|
        group_permissions[type] += 1 if permissions.any? { |p| p[type.to_s] == true }
      end
    end
    group_permissions
  end
end
