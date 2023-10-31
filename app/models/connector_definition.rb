# frozen_string_literal: true

class ConnectorDefinition < ApplicationRecord
  validates :connector_type, presence: true
  validates :source_type, presence: true, if: :source?
  validates :spec, presence: true
  validates :meta_data, presence: true

  enum :connector_type, %i[source destination]
  enum :source_type, %i[database api]

  # TODO: - Validate spec and meta_data using JSON schema
  has_many :sources, dependent: :nullify, class_name: "Connector"
  has_many :destinations, dependent: :nullify, class_name: "Connector"
end
