# frozen_string_literal: true

module Billing
  class Plan < ApplicationRecord
    validates :name, presence: true

    enum status: { inactive: 0, active: 1 }
    enum currency: { usd: 0 }
    enum interval: { monthly: 0, year: 1 }

    has_many :subscriptions, dependent: :nullify
  end
end
