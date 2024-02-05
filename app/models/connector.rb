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

  # TODO: move the method to integration gem
  def execute_query(query, limit: 50)
    connection_config = configuration.with_indifferent_access
    client = connector_client.new
    db = client.send(:create_connection, connection_config)
    query = query.chomp(";")

    # Check if the query already has a LIMIT clause
    has_limit = query.match?(/LIMIT \s*\d+\s*$/i)
    # Append LIMIT only if not already present
    final_query = has_limit ? query : "#{query} LIMIT #{limit}"
    client.send(:query, db, final_query)
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
