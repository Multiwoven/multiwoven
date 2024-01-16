# frozen_string_literal: true

class Connector < ApplicationRecord
  validates :workspace_id, presence: true
  validates :connector_type, presence: true
  validates :configuration, presence: true, json: { schema: -> { configuration_schema } }

  # User defined name for this connector eg: reporting warehouse
  validates :name, presence: true
  # Connector name eg: snowflake
  validates :connector_name, presence: true

  enum :connector_type, %i[source destination]

  belongs_to :workspace

  has_many :models, dependent: :nullify
  has_one :catalog, dependent: :nullify

  def connector_definition
    @connector_definition ||= connector_client.new.meta_data.with_indifferent_access
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
      connection_specification: configuration
    )
  end

  def connector_client
    Multiwoven::Integrations::Service
      .connector_class(
        connector_type.to_s.camelize, connector_name.to_s.camelize
      )
  end
end
