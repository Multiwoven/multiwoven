# frozen_string_literal: true

class Eula < ApplicationRecord
  validates :organization_id, presence: true
  validates :status, presence: true

  enum :status, %i[disabled enabled]

  belongs_to :organization

  has_one_attached :file
end
