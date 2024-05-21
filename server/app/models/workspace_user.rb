# frozen_string_literal: true

# == Schema Information
#
# Table name: workspace_users
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  workspace_id :bigint
#  role_id      :bigint           # Changed from role to role_id
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# app/models/workspace_user.rb

class WorkspaceUser < ApplicationRecord
  belongs_to :user
  belongs_to :workspace
  belongs_to :role

  scope :admins, -> { joins(:role).where("roles.role_name = ?", "Admin") }

  def admin?
    role.role_name == "Admin"
  end

  def member?
    role.role_name == "Member"
  end

  def viewer?
    role.role_name == "Viewer"
  end
end
