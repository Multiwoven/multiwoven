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

  enum :query_type, %i[raw_sql dbt soql table_selector ai_ml]

  validates :query, presence: true, if: :requires_query?
  # Havesting configuration
  validates :configuration, presence: true, if: :requires_configuration?

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

  def requires_query?
    %w[raw_sql dbt soql table_selector].include?(query_type)
  end

  def requires_configuration?
    %w[ai_ml].include?(query_type)
  end
end
