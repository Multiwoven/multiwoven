# frozen_string_literal: true

module Billing
  class Subscription < ApplicationRecord
    belongs_to :organization
    belongs_to :plan

    enum status: {
      trial: 0,
      active: 1,
      past_due: 2,
      canceled: 3,
      unpaid: 4,
      paused: 5
    }

    validates :status, presence: true
    validates :data_app_sessions, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :feedback_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :rows_synced, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end
end
