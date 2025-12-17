# frozen_string_literal: true

class KnowledgeBase < ApplicationRecord
  EMBEDDING_CONFIG_JSON_SCHEMA = Rails.root.join(
    "app/models/schema_validations/knowledge_bases/configuration_embedding.json"
  )
  STORAGE_CONFIG_JSON_SCHEMA = Rails.root.join(
    "app/models/schema_validations/knowledge_bases/configuration_storage.json"
  )

  belongs_to :workspace
  belongs_to :hosted_data_store, optional: true
  belongs_to :source_connector, class_name: "Connector", optional: true
  belongs_to :destination_connector, class_name: "Connector", optional: true
  has_many :knowledge_base_files, class_name: "Agents::KnowledgeBaseFile", dependent: :destroy

  enum :knowledge_base_type, { vector_store: 0, semantic_data_model: 1 }

  validates :name, presence: true
  validates :knowledge_base_type, presence: true
  validates :size, presence: true
  validates :embedding_config, presence: true, json: { schema: lambda {
                                                                 embedding_config_schema_validation
                                                               } }
  validates :storage_config, presence: true, json: { schema: lambda {
                                                               storage_config_schema_validation
                                                             } }

  private

  def embedding_config_schema_validation
    EMBEDDING_CONFIG_JSON_SCHEMA
  end

  def storage_config_schema_validation
    STORAGE_CONFIG_JSON_SCHEMA
  end
end
