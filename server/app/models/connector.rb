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
# rubocop:disable Metrics/ClassLength
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

  before_save :set_sub_category
  before_update :set_sub_category, if: :will_save_change_to_connector_name?

  DEFAULT_CONNECTOR_CATEGORY = "data"
  DEFAULT_CONNECTOR_SUB_CATEGORY = "database"

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

  LLM_SUB_CATEGORIES = [
    "LLM"
  ].freeze

  DATABASE_SUB_CATEGORIES = [
    "Relational Database",
    "database"
  ].freeze

  WEB_SUB_CATEGORIES = [
    "Web Scraper"
  ].freeze

  AI_ML_SERVICE_SUB_CATEGORIES = [
    "AI_ML Service"
  ].freeze

  VECTOR_SUB_CATEGORIES = [
    "Vector Database"
  ].freeze

  scope :ai_ml, -> { where(connector_category: AI_ML_CATEGORIES) }
  scope :data, -> { where(connector_category: DATA_CATEGORIES) }

  scope :llm, -> { where(connector_sub_category: LLM_SUB_CATEGORIES) }
  scope :database, -> { where(connector_sub_category: DATABASE_SUB_CATEGORIES) }
  scope :web, -> { where(connector_sub_category: WEB_SUB_CATEGORIES) }
  scope :ai_ml_service, -> { where(connector_sub_category: AI_ML_SERVICE_SUB_CATEGORIES) }
  scope :vector, -> { where(connector_sub_category: VECTOR_SUB_CATEGORIES) }

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

    if connector_name == "Postgresql"
      query = "SET search_path TO \"#{connection_config[:schema]}\", \"public\"; #{query}"
    end

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

  def execute_search(vector, limit)
    connection_config = resolved_configuration.with_indifferent_access
    if connector_name == "Postgresql"
      vector = "SET search_path TO \"#{connection_config[:schema]}\", \"public\"; #{vector}::vector"

    end

    vector_search_config = Multiwoven::Integrations::Protocol::VectorConfig.new(
      source: to_protocol,
      vector:,
      limit:
    )
    client = connector_client.new
    client.send(:search, vector_search_config)
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
      query_type: connector_query_type,
      connector_instance: self
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

  def set_sub_category
    unless connector_sub_category.present? &&
           connector_sub_category == DEFAULT_CONNECTOR_SUB_CATEGORY &&
           !will_save_change_to_connector_sub_category?
      return
    end

    sub_category_name = connector_client.new.meta_data[:data][:sub_category]
    sub_category_name = "Vector Database" if resolved_configuration["data_type"] == "vector"
    self.connector_sub_category = sub_category_name if sub_category_name.present?
  rescue StandardError => e
    Rails.logger.error("Failed to set sub category for connector ##{id}: #{e.message}")
  end

  def ai_model?
    connector_category == "AI Model"
  end

  def resolved_configuration
    resolve_values_from_env(configuration)
  end

  def masked_configuration
    spec = connector_client.new.connector_spec[:connection_specification].with_indifferent_access
    secret_keys = extract_secret_keys(spec)
    mask_secret_values(configuration.deep_dup, secret_keys)
  end

  private

  def extract_secret_keys(schema, keys = [])
    return keys unless schema.is_a?(Hash)

    properties = schema[:properties]
    if properties.is_a?(Hash)
      properties.each do |key, subschema|
        keys << key.to_s if subschema[:multiwoven_secret] || subschema["multiwoven_secret"]
        extract_secret_keys(subschema, keys)
      end
    end

    keys
  end

  def mask_secret_values(config, secret_keys)
    case config
    when Hash
      config.each_with_object({}) do |(key, value), result|
        result[key] =
          if secret_keys.include?(key.to_s)
            "*************"
          else
            mask_secret_values(value, secret_keys)
          end
      end
    when Array
      config.map { |item| mask_secret_values(item, secret_keys) }
    else
      config
    end
  end
end
# rubocop:enable Metrics/ClassLength
