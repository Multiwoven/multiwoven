# frozen_string_literal: true

class Catalog < ApplicationRecord
  belongs_to :workspace
  belongs_to :connector

  validates :workspace_id, presence: true
  validates :connector_id, presence: true
  validates :catalog, presence: true
  validates :catalog_hash, presence: true # 32-bit Murmur3 hash

  # TODO: - Validate catalog using JSON schema
end
