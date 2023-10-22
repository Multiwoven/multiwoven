# frozen_string_literal: true

# == Schema Information
#
# Table name: workspaces
#
#  id           :bigint           not null, primary key
#  api_key      :string
#  name         :string
#  slug         :string
#  status       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :string
#
# Indexes
#
#  index_workspaces_on_name          (name) UNIQUE
#  index_workspaces_on_slug          (slug) UNIQUE
#  index_workspaces_on_workspace_id  (workspace_id) UNIQUE
#
class Workspace < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :workspace_id, uniqueness: true
  validates :status, inclusion: { in: %w[active inactive pending] }

  before_validation :generate_slug_and_id_and_status, on: :create

  private

  def generate_slug_and_id_and_status
    self.slug ||= name.parameterize if name
    self.workspace_id ||= SecureRandom.uuid
    self.api_key ||= SecureRandom.hex(32)
    self.status ||= "pending" # Setting the default status as 'pending'. Change this if you have another preference.
  end
end
