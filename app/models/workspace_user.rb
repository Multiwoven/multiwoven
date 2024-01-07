# frozen_string_literal: true

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
