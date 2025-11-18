# frozen_string_literal: true

class HostedDataStore < ApplicationRecord
  belongs_to :workspace
  belongs_to :source_connector, class_name: "Connector", optional: true
  belongs_to :destination_connector, class_name: "Connector", optional: true
  has_many :hosted_data_store_tables, dependent: :destroy

  enum :database_type, { vector_db: 0, raw_sql: 1 }
  enum :state, { disabled: 0, enabled: 1 }

  validates :name, presence: true
  validates :database_type, presence: true
  validates :description, presence: true
  validates :state, presence: true
end
