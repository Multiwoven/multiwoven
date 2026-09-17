# frozen_string_literal: true

class LlmUsageEvent < ApplicationRecord
  TOKEN_COLUMNS = %i[input_tokens output_tokens reasoning_tokens cache_read_tokens cache_write_tokens].freeze

  belongs_to :organization
  belongs_to :workspace
  belongs_to :user, optional: true
  belongs_to :role, optional: true
  belongs_to :connector, optional: true
  belongs_to :pricing, class_name: "ModelPricing", optional: true

  enum :source, %i[workflow data_app execute_model mcp_tool embeddings]
  enum :token_count_method, %i[reported estimated hybrid unavailable]
  enum :status, %i[success error interrupted]

  validates :request_id, presence: true
  validates :provider, presence: true
  validates :model, presence: true
  validates(*TOKEN_COLUMNS, numericality: { only_integer: true, greater_than_or_equal_to: 0 })
  validates :cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  # Half open, because counter windows meet end to start and a boundary event belongs to one only.
  scope :created_between, ->(from, to) { where(created_at: from...to) }
  scope :unpriced, -> { where(cost: nil) }

  def readonly?
    persisted?
  end

  def total_tokens
    TOKEN_COLUMNS.sum { |column| public_send(column).to_i }
  end

  def unpriced?
    cost.nil?
  end
end
