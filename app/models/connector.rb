# frozen_string_literal: true

class Connector < ApplicationRecord
  validates :workspace_id, presence: true
  validates :connector_definition_id, presence: true
  validates :connector_type, presence: true
  validates :configuration, presence: true
  validates :name, presence: true

  enum :connector_type, %i[source destination]

  belongs_to :workspace
  belongs_to :connector_definition

  has_many :models, dependent: :nullify
  has_many :catalog, dependent: :nullify

  # TODO: - Validate configuration using JSON schema
end
