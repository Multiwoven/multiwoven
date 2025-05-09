# frozen_string_literal: true

# == Schema Information
#
# Table name: connectors
#
#  id                      :bigint           not null, primary key
#  workspace_id            :integer
#  connector_type          :integer
#  connector_definition_id :integer
#  configuration           :jsonb
#  name                    :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  connector_name          :string
#
class Connector < ApplicationRecord
  include Utils::JsonHelpers

  validates :workspace_id, presence: true
  validates :connector_type, presence: true
  validates :configuration, presence: true, json: { schema: -> { configuration_schema } }

  # User defined name for this connector eg: reporting warehouse
  validates :name, presence: true
  # Connector name eg: snowflake
  validates :connector_name, presence: true

  enum :connector_type, %i[source destination]

  belongs_to :workspace

  has_many :models, dependent: :destroy
  has_many :source_syncs, class_name: "Sync", foreign_key: "source_id", dependent: :destroy # rubocop:disable Rails/InverseOf
  has_many :destination_syncs, class_name: "Sync", # rubocop:disable Rails/InverseOf
                               foreign_key: "destination_id", dependent: :destroy
  has_one :catalog, dependent: :destroy

  default_scope { order(updated_at: :desc) }

  before_save :set_category
  before_update :set_category, if: :will_save_change_to_connector_name?

  DEFAULT_CONNECTOR_CATEGORY = "data"

  # TODO: Move this to integrations gem
  DATA_CATEGORIES = [
    "Data Warehouse",
    "Retail",
    "Data Lake",
    "Database",
    "Marketing Automation",
    "CRM",
    "Ad-Tech",
    "Team Collaboration",
    "Productivity Tools",
    "Payments",
    "File Storage",
    "HTTP",
    "Customer Support",
    "data"
  ].freeze

  AI_ML_CATEGORIES = [
    "AI Model"
  ].freeze

  scope :ai_ml, -> { where(connector_category: AI_ML_CATEGORIES) }
  scope :data, -> { where(connector_category: DATA_CATEGORIES) }

  def connector_definition
    @connector_definition ||= connector_client.new.meta_data.with_indifferent_access
  end

  def icon
    @connector_definition ||= connector_client.new.meta_data.with_indifferent_access
    @connector_definition.dig(:data, :icon)
  end

  # TODO: move the method to integration gem
  def execute_query(query, limit: 50)
    connection_config = resolved_configuration.with_indifferent_access
    client = connector_client.new
    db = client.send(:create_connection, connection_config)
    query = query.chomp(";")

    # Check if the query already has a LIMIT clause
    has_limit = query.match?(/LIMIT \s*\d+\s*$/i)
    # Append LIMIT only if not already present
    final_query = has_limit ? query : "#{query} LIMIT #{limit}"
    client.send(:query, db, final_query)
  end

  def generate_response(payload)
    connection_config = resolved_configuration.with_indifferent_access
    client = connector_client.new
    client.send(:run_model, connection_config, JSON.parse(payload))
  end

  def configuration_schema
    client = Multiwoven::Integrations::Service
             .connector_class(
               connector_type.to_s.camelize, connector_name.to_s.camelize
             ).new
    client.connector_spec[:connection_specification].to_json
  end

  def to_protocol
    Multiwoven::Integrations::Protocol::Connector.new(
      name: connector_name,
      type: connector_type,
      connection_specification: resolved_configuration,
      query_type: connector_query_type
    )
  end

  def connector_client
    Multiwoven::Integrations::Service
      .connector_class(
        connector_type.to_s.camelize, connector_name.to_s.camelize
      )
  end

  def connector_query_type
    client = Multiwoven::Integrations::Service
             .connector_class(
               connector_type.to_s.camelize, connector_name.to_s.camelize
             ).new
    connector_spec = client.connector_spec
    connector_spec&.connector_query_type || "raw_sql"
  end

  def pull_catalog
    connector_client.new.discover(resolved_configuration).catalog.to_h.with_indifferent_access
  end

  def set_category
    unless connector_category.present? &&
           connector_category == DEFAULT_CONNECTOR_CATEGORY &&
           !will_save_change_to_connector_category?
      return
    end

    category_name = connector_client.new.meta_data[:data][:category]
    self.connector_category = category_name if category_name.present?
  rescue StandardError => e
    Rails.logger.error("Failed to set category for connector ##{id}: #{e.message}")
  end

  def ai_model?
    connector_category == "AI Model"
  end

  def resolved_configuration
    resolve_values_from_env(configuration)
  end
end
