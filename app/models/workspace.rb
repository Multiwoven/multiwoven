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
#
# Indexes
#
#  index_workspaces_on_name          (name) UNIQUE
#  index_workspaces_on_slug          (slug) UNIQUE
#
class Workspace < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active inactive pending] }

  has_many :workspace_users, dependent: :nullify
  has_many :users, through: :workspace_users
  has_many :connectors, dependent: :nullify
  has_many :models, dependent: :nullify
  has_many :catalogs, dependent: :nullify
  has_many :syncs, dependent: :nullify

  before_validation :generate_slug_and_status, on: :create
  before_update :update_slug, if: :name_changed?

  private

  def generate_slug_and_status
    self.slug ||= name.parameterize if name
    self.api_key ||= SecureRandom.hex(32)
    self.status ||= "pending" # Setting the default status as 'pending'. Change this if you have another preference.
  end

  def update_slug
    self.slug = name.parameterize if name.present?
  end
end
