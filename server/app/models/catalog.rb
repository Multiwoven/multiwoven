# frozen_string_literal: true

# == Schema Information
#
# Table name: catalogs
#
#  id           :bigint           not null, primary key
#  workspace_id :integer
#  connector_id :integer
#  catalog      :jsonb
#  catalog_hash :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
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
    if stream["request_rate_limit"] && !stream["request_rate_limit"].zero?
      # stream specific rate limit
      request_rate_limit = stream["request_rate_limit"]
      request_rate_limit_unit = stream["request_rate_limit_unit"]
      request_rate_concurrency = stream["request_rate_concurrency"]
    else
      # global rate limit
      request_rate_limit = catalog["request_rate_limit"]
      request_rate_limit_unit = catalog["request_rate_limit_unit"]
      request_rate_concurrency = catalog["request_rate_concurrency"]
    end
    Multiwoven::Integrations::Protocol::Stream.new(
      name: stream[:name],
      url: stream[:url],
      json_schema: stream[:json_schema],
      request_method: stream[:request_method],
      batch_support: stream[:batch_support],
      batch_size: stream[:batch_size],
      request_rate_limit:,
      request_rate_limit_unit:,
      request_rate_concurrency:
    )
  end
end
