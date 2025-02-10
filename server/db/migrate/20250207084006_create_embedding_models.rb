class CreateEmbeddingModels < ActiveRecord::Migration[7.1]
  def change
    create_table :embedding_models do |t|
      t.string :mode, null: false
      t.integer :status, default: 1
      t.string :models, null: false, array: true, default: []

      t.timestamps
    end

  end
end
