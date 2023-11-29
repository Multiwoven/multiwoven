# frozen_string_literal: true

# app/models/workspace_user.rb

class WorkspaceUser < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  # TODO: use enum here
  validates :role, inclusion: { in: %w[admin member viewer] } # Define roles or use an enum

  def admin?
    role == "admin"
  end
end
