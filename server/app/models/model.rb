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
  validates :workspace_id, presence: true
  validates :connector_id, presence: true
  validates :name, presence: true
  validates :query, presence: true
  validates :primary_key, presence: true
  enum :query_type, %i[raw_sql dbt soql table_selector]

  belongs_to :workspace
  belongs_to :connector

  has_many :syncs, dependent: :destroy

  default_scope { order(updated_at: :desc) }

  def to_protocol
    Multiwoven::Integrations::Protocol::Model.new(
      name:,
      query:,
      query_type:,
      primary_key:
    )
  end
end
