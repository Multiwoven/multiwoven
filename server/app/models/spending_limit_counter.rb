# frozen_string_literal: true

class SpendingLimitCounter < ApplicationRecord
  belongs_to :spending_limit

  # The FK cascade is what a window restart relies on; this covers only counter.destroy.
  has_many :spending_limit_alerts, dependent: :delete_all

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

  # One statement, because a worker for another threshold writes the same column concurrently.
  def record_threshold!(threshold)
    value = threshold.to_i
    append = ["alerted_thresholds = (SELECT array_agg(DISTINCT t ORDER BY t) " \
              "FROM unnest(alerted_thresholds || ?::integer) AS t)", value]

    self.class.where(id:)
        .where.not("alerted_thresholds @> ARRAY[?]::integer[]", value)
        .update_all(append) # rubocop:disable Rails/SkipsModelValidations
  end
end
