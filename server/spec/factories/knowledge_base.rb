# frozen_string_literal: true

FactoryBot.define do
  factory :knowledge_base do
    association :workspace

    name { "My Knowledge Base" }
    knowledge_base_type { "vector_store" }
    size { 100 }
    embedding_config do
      {
        "embedding_provider" => "open_ai",
        "embedding_model" => "text-embedding-3-small",
        "api_key" => "test_api_key",
        "chunk_size" => 100,
        "chunk_overlap" => 20
      }
    end
    storage_config do
      {
        "table_name" => "test_table",
        "vector_column_name" => "test_vector_column",
        "text_column_name" => "test_text_column",
        "metadata_column_name" => "test_metadata_column"
      }
    end
  end
end
