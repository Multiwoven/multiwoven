# frozen_string_literal: true

class Alert < ApplicationRecord
  belongs_to :workspace
  has_many :alert_channels, dependent: :destroy
  accepts_nested_attributes_for :alert_channels

  validates :workspace_id, presence: true
  validates :row_failure_threshold_percent, numericality: { only_integer: true, allow_nil: true }
end
