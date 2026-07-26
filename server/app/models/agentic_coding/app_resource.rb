# frozen_string_literal: true

module AgenticCoding
  class AppResource < ApplicationRecord
    serialize :credentials, coder: JSON, type: Hash

    belongs_to :agentic_coding_app, class_name: "AgenticCoding::App"

    validates :resource_type, presence: true,
                              uniqueness: {
                                scope: :agentic_coding_app_id,
                                conditions: -> { where.not(status: "deleted") }
                              }
    validates :status, presence: true,
                       inclusion: { in: %w[provisioning provisioned failed deleted] }
  end
end
