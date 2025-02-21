# frozen_string_literal: true

class UpdateModeInEmbeddingModels < ActiveRecord::Migration[7.1]
  def up
    EmbeddingModel.find_by(mode: "openai")&.update(mode: "open_ai")
  end

  def down
    EmbeddingModel.find_by(mode: "open_ai")&.update(mode: "openai")
  end
end
