# frozen_string_literal: true

class SpendingLimitCounter < ApplicationRecord
  belongs_to :spending_limit

  validates :window_start, presence: true, uniqueness: { scope: :spending_limit_id }
  validates :spent_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :spent_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :request_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unpriced_requests, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent, -> { order(window_start: :desc) }
  scope :for_window, ->(window_start) { where(window_start:) }

  def alerted?(threshold)
    alerted_thresholds.include?(threshold)
  end
end
