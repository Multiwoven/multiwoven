# frozen_string_literal: true

# == Schema Information
#
# Table name: models
#
#  id           :bigint           not null, primary key
#  name         :string
#  workspace_id :integer
#  connector_id :integer
#  query        :text
#  query_type   :integer
#  primary_key  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Model < ApplicationRecord
  AI_ML_CONFIG_JSON_SCHEMA = Rails.root.join("app/models/schema_validations/models/configuration_aiml.json")
  DYNAMIC_SQL_CONFIG_JSON_SCHEMA = Rails.root.join(
    "app/models/schema_validations/models/configuration_dynamic_sql.json"
  )
  UNSTRUCTURED_CONFIG_JSON_SCHEMA = Rails.root.join(
    "app/models/schema_validations/models/configuration_unstructured.json"
  )
  VECTOR_SEARCH_CONFIG_JSON_SCHEMA = Rails.root.join(
    "app/models/schema_validations/models/configuration_vector_search.json"
  )

  validates :workspace_id, presence: true
  validates :connector_id, presence: true
  validates :name, presence: true

  enum :query_type, %i[raw_sql dbt soql table_selector ai_ml dynamic_sql unstructured vector_search]

  validates :query, presence: true, if: :requires_query?
  # Havesting configuration
  validates :configuration, presence: true, if: :requires_configuration?
  validates :configuration, presence: true, json: { schema: lambda {
                                                              configuration_schema_validation
                                                            } }, if: :requires_configuration?

  belongs_to :workspace
  belongs_to :connector

  has_many :syncs, dependent: :destroy
  has_many :visual_components, dependent: :destroy

  scope :data, -> { where(query_type: %i[raw_sql dbt soql table_selector dynamic_sql]) }
  scope :ai_ml, -> { where(query_type: :ai_ml) }
  scope :unstructured, -> { where(query_type: :unstructured) }
  scope :vector_search, -> { where(query_type: :vector_search) }

  default_scope { order(updated_at: :desc) }

  def to_protocol
    Multiwoven::Integrations::Protocol::Model.new(
      name:,
      query:,
      query_type:,
      primary_key:
    )
  end

  def requires_query?
    %w[raw_sql dbt soql table_selector].include?(query_type)
  end

  def requires_configuration?
    %w[ai_ml dynamic_sql unstructured vector_search].include?(query_type)
  end

  def json_schema
    configuration["json_schema"]
  end

  private

  def configuration_schema_validation
    if ai_ml?
      AI_ML_CONFIG_JSON_SCHEMA
    elsif dynamic_sql?
      DYNAMIC_SQL_CONFIG_JSON_SCHEMA
    elsif unstructured?
      UNSTRUCTURED_CONFIG_JSON_SCHEMA
    elsif vector_search?
      VECTOR_SEARCH_CONFIG_JSON_SCHEMA
    end
  end
end
