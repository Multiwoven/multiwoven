# frozen_string_literal: true

module AgenticCoding
  class Deployment < ApplicationRecord
    belongs_to :workspace
    belongs_to :agentic_coding_app, class_name: "AgenticCoding::App", inverse_of: :deployments
    belongs_to :agentic_coding_session, class_name: "AgenticCoding::Session", inverse_of: :deployments

    enum status: {
      pending: 0,
      running: 1,
      succeeded: 2,
      failed: 3
    }

    validates :status, presence: true
  end
end
