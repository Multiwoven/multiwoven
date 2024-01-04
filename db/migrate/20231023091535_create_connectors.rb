# frozen_string_literal: true

class CreateConnectors < ActiveRecord::Migration[7.1]
  def change
    create_table :connectors do |t|
      t.integer :workspace_id
      t.integer :connector_type
      t.jsonb :configuration
      t.string :name

      t.timestamps
    end
  end
end
