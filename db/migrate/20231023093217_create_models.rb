class CreateModels < ActiveRecord::Migration[7.1]
  def change
    create_table :models do |t|
      t.string :name
      t.integer :workspace_id
      t.integer :connector_id
      t.text :query
      t.integer :query_type
      t.string :primary_key

      t.timestamps
    end
  end
end
