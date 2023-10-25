# frozen_string_literal: true

class Model < ApplicationRecord
  validates :workspace_id, presence: true
  validates :connector_id, presence: true
  validates :name, presence: true
  validates :query, presence: true
  enum :query_type, %i[raw_sql]

  belongs_to :workspace
  belongs_to :connector

  has_many :syncs, dependent: :nullify
end
