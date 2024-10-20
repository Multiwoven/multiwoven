# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Organization < ApplicationRecord
  validates :name, presence: true

  has_many :workspaces, dependent: :destroy
  has_many :workspace_users, through: :workspaces
  has_many :users, through: :workspace_users
end
