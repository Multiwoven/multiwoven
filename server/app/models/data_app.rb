# frozen_string_literal: true

class DataApp < ApplicationRecord
  validates :workspace_id, presence: true
  validates :status, presence: true
  validates :name, presence: true

  enum :status, %i[inactive active draft]

  belongs_to :workspace
  has_many :visual_components, dependent: :destroy
  has_many :models, through: :visual_components

  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :draft
  end
end
