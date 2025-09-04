# frozen_string_literal: true

module Agents
  class RemoteCodeExecution < ApplicationRecord
    belongs_to :workflow_run, optional: true
    belongs_to :workspace
    belongs_to :component, class_name: "Agents::Component", optional: true

    validates :provider, presence: true
    validates :mode, presence: true
    validates :status, presence: true
    validates :invocation_id, length: { maximum: 100 }

    enum :mode, %i[test workflow]
    enum :status, %i[success error]
    enum :provider, %i[aws_lambda]

    def duration_seconds
      execution_time_ms.present? ? execution_time_ms / 1000.0 : nil
    end
  end
end
