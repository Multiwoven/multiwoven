# frozen_string_literal: true

class Catalog < ApplicationRecord
  belongs_to :workspace
  belongs_to :connector

  validates :workspace_id, presence: true
  validates :connector_id, presence: true
  validates :catalog, presence: true
  validates :catalog_hash, presence: true

  def find_stream_by_name(name)
    catalog["streams"].find { |stream| stream["name"] == name }
  end

  def stream_to_protocol(stream)
    stream = stream.with_indifferent_access
    Multiwoven::Integrations::Protocol::Stream.new(
      name: stream[:name],
      url: stream[:url],
      json_schema: stream[:json_schema],
      request_method: stream[:request_method]
    )
  end
end
