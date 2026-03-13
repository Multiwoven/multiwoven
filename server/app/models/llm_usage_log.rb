# frozen_string_literal: true

# == Schema Information
#
# Table name: llm_usage_logs
#
#  id                     :bigint           not null, primary key
#  workspace_id           :bigint           not null
#  workflow_run_id        :bigint           not null
#  component_id           :string           not null
#  connector_id           :string           not null
#  prompt_hash            :string           not null
#  estimated_input_tokens :integer          not null
#  estimated_output_tokens :integer          not null
#  selected_model         :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class LlmUsageLog < ApplicationRecord
  belongs_to :workspace
  belongs_to :workflow_run, class_name: "Agents::WorkflowRun"
  belongs_to :component, class_name: "Agents::Component", inverse_of: :llm_usage_logs

  validates :prompt_hash, presence: true
  validates :estimated_input_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :estimated_output_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :selected_model, presence: true
  validates :connector_id, presence: true
  validates :component_id, presence: true
  validates :provider, presence: true
  validates :total_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }
end
