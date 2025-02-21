# frozen_string_literal: true

class CreateEmbeddingModelOpenai < ActiveRecord::Migration[7.1]
  def up
    EmbeddingModel.create!(
      mode: "openai",
      models: [
        "text-embedding-3-small",
        "text-embedding-3-large",
        "text-embedding-ada-002"
      ]
    )
  end

  def down
    EmbeddingModel.where(mode: "openai").destroy_all
  end
end
