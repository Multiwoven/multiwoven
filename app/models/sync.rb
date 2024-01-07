# frozen_string_literal: true

class Sync < ApplicationRecord
  validates :workspace_id, presence: true
  validates :source_id, presence: true
  validates :destination_id, presence: true
  validates :model_id, presence: true
  validates :configuration, presence: true
  # TODO: Add primary key and cursor field
  validates :schedule_type, presence: true
  validates :schedule_data, presence: true
  validates :status, presence: true

  enum :schedule_type, %i[manual automated]
  enum :status, %i[healthy failed aborted in_progress disabled]

  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  belongs_to :model

  # TODO: - Validate schedule data using JSON schema
end
