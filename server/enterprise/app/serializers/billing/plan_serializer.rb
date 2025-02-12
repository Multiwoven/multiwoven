# frozen_string_literal: true

module Billing
  class PlanSerializer < ActiveModel::Serializer
    attributes :id, :name, :status, :amount, :currency, :interval,
               :max_data_app_sessions, :max_feedback_count, :max_rows_synced,
               :addons
  end
end
