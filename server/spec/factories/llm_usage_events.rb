# frozen_string_literal: true

FactoryBot.define do
  factory :llm_usage_event do
    association :workspace

    organization { workspace.organization }
    request_id { SecureRandom.uuid }
    source { :workflow }
    source_ref { {} }
    provider { "openai" }
    model { "gpt-4o-mini" }
    input_tokens { 1000 }
    output_tokens { 200 }
    reasoning_tokens { 0 }
    cache_read_tokens { 500 }
    cache_write_tokens { 0 }
    token_count_method { :reported }
    cost { 0.005400 }
    status { :success }

    trait :unpriced do
      cost { nil }
    end

    trait :estimated do
      token_count_method { :estimated }
    end

    trait :failed do
      status { :error }
    end
  end
end
