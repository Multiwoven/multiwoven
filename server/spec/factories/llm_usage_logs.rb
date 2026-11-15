# frozen_string_literal: true

FactoryBot.define do
  factory :llm_usage_log do
    association :workspace
    association :workflow_run

    prompt_hash { Digest::SHA256.hexdigest("test prompt #{SecureRandom.hex(8)}") }
    estimated_input_tokens { 100 }
    estimated_output_tokens { 200 }
    selected_model { "GPT-4 Turbo" }
    connector_id { "conn_#{SecureRandom.hex(4)}" }
    component_id { "comp_#{SecureRandom.hex(4)}" }
    provider { "openai" }
    total_cost { 0.0 }
  end
end
