# frozen_string_literal: true

FactoryBot.define do
  factory :embedding_model do
    mode { "openai" }
    status { 1 }
    models { ["text-embedding-3-small", "text-embedding-3-large"] }

    trait :inactive do
      status { 0 }
    end

    trait :with_custom_models do
      models { ["text-embedding-ada-002"] }
    end
  end
end
