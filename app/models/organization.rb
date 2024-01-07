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
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  has_many :workspaces, dependent: :destroy
end
