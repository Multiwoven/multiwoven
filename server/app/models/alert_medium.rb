# frozen_string_literal: true

class AlertMedium < ApplicationRecord
  has_many :alert_channels, dependent: :destroy

  validates :platform, presence: true, inclusion: { in: %w[email slack] }
  enum :platform, %i[email slack]
end
