# frozen_string_literal: true

class AlertChannel < ApplicationRecord
  belongs_to :alert

  validates :platform, presence: true, inclusion: { in: %w[email slack] }
  enum :platform, %i[email slack]
end
