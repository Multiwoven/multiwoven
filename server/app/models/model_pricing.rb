# frozen_string_literal: true

class ModelPricing < ApplicationRecord
  RATE_COLUMNS = %i[input_rate output_rate cache_read_rate cache_write_rate].freeze

  # llm_usage_events.cost carries no currency, so a non USD rate would corrupt every counter.
  SUPPORTED_CURRENCIES = %w[USD].freeze

  enum :source, %i[sync manual]

  validates :provider, presence: true
  validates :model, presence: true
  validates :currency, presence: true, inclusion: { in: SUPPORTED_CURRENCIES }
  validates :effective_from, presence: true
  validates :input_rate, :output_rate, :cache_read_rate, :cache_write_rate,
            numericality: { greater_than_or_equal_to: 0 }
  validate :effective_to_after_effective_from

  scope :in_force_at, lambda { |time|
    where("effective_from <= :time AND (effective_to IS NULL OR effective_to > :time)", time:)
  }
  scope :in_force, -> { where(effective_to: nil) }
  scope :for_model, ->(provider, model) { where(provider:, model:) }

  def same_rates?(rates)
    RATE_COLUMNS.all? { |column| public_send(column).to_d == rates[column].to_d }
  end

  private

  def effective_to_after_effective_from
    return if effective_to.blank? || effective_from.blank?
    return if effective_to > effective_from

    errors.add(:effective_to, "must be after effective_from")
  end
end
