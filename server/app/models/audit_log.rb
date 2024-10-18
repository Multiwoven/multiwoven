# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  validates :action, :resource_type, :workspace_id, presence: true
end
