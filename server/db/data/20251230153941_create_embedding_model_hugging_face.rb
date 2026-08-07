class CreateEmbeddingModelHuggingFace < ActiveRecord::Migration[7.1]
  def up
    EmbeddingModel.create!(
      mode: "hugging_face",
      models: [
        "all-MiniLM-L6-v2",
        "all-mpnet-base-v2",
        "paraphrase-MiniLM-L12-v2",
        "multi-qa-MiniLM-L6-cos-v1",
        "msmarco-MiniLM-L6-cos-v5"
      ]
    )
  end

  def down
    EmbeddingModel.where(mode: "hugging_face").destroy_all
  end
end
