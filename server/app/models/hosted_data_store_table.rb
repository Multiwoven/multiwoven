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

  def self.update_status!(hosted_data_store:, table_name:, status:)
    table = hosted_data_store.hosted_data_store_tables.find_by(name: table_name)
    if table.nil?
      Rails.logger.warn("HostedDataStoreTable '#{table_name}' not found for hosted_data_store ##{hosted_data_store.id}")
      return
    end

    table.update!(sync_enabled: status)
  end
end
