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
# app/models/workspace_user.rb

class WorkspaceUser < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  ADMIN = "admin"
  MEMBER = "member"
  VIEWER = "viewer"

  # TODO: use enum here
  validates :role, inclusion: { in: [ADMIN, MEMBER, VIEWER] }

  def admin?
    role == ADMIN
  end
end
