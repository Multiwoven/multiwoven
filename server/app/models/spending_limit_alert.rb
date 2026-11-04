# frozen_string_literal: true

class SpendingLimitAlert < ApplicationRecord
  # Configurable thresholds stop at 99; reaching the cap always alerts.
  MAX_THRESHOLD = 100

  belongs_to :spending_limit_counter

  validates :threshold, presence: true,
                        numericality: { only_integer: true,
                                        greater_than_or_equal_to: SpendingLimit::MIN_ALERT_THRESHOLD,
                                        less_than_or_equal_to: MAX_THRESHOLD },
                        uniqueness: { scope: :spending_limit_counter_id }

  CLAIM_TTL = 15.minutes

  scope :pending, lambda {
    where(delivered_at: nil, abandoned_at: nil)
      .where("claimed_at IS NULL OR claimed_at < ?", CLAIM_TTL.ago)
  }

  # ON CONFLICT, not a rescued create!: a uniqueness violation would abort the enclosing
  # transaction and roll back the counter movement it shares.
  def self.record_missing(counter, thresholds)
    rows = Array(thresholds).map { |threshold| { spending_limit_counter_id: counter.id, threshold: threshold.to_i } }
    return [] if rows.empty?

    result = insert_all( # rubocop:disable Rails/SkipsModelValidations
      rows, unique_by: :index_spend_alerts_on_counter_and_threshold, returning: :id, record_timestamps: true
    )
    result.rows.flatten
  end

  # Only for a crossing that can never mean anything again; every other skip state can come back.
  def abandon!
    update!(abandoned_at: Time.current)
  end

  def delivered?
    delivered_at.present?
  end
end
