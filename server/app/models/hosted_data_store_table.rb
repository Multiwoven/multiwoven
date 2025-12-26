# frozen_string_literal: true

class HostedDataStoreTable < ApplicationRecord
  belongs_to :hosted_data_store
  belongs_to :source_connector, class_name: "Connector", optional: true
  belongs_to :destination_connector, class_name: "Connector", optional: true
  enum :sync_enabled, { disabled: 0, enabled: 1 }

  validates :name, presence: true
  validates :column_count, presence: true
  validates :row_count, presence: true
  validates :size, presence: true
  validates :table_schema, presence: true
end
