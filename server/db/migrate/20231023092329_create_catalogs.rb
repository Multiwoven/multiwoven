# frozen_string_literal: true

class CreateCatalogs < ActiveRecord::Migration[7.1]
  def change
    create_table :catalogs do |t|
      t.integer :workspace_id
      t.integer :connector_id
      t.jsonb :catalog
      t.integer :catalog_hash

      t.timestamps
    end
  end
end
