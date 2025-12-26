# frozen_string_literal: true

class CreateTools < ActiveRecord::Migration[7.1]
  def change
    create_table :tools, id: :uuid do |t|
      t.string :name, null: false
      t.string :label
      t.text :description

      t.integer :tool_type, null: false

      t.jsonb :configuration, default: {}, null: false # tool-specific config (MCP, KB, etc.)
      t.jsonb :metadata, default: {} # optional extra info (icon, category, source)

      t.boolean :enabled, default: true, null: false

      t.references :workspace, type: :bigint, foreign_key: true, null: false

      t.timestamps
    end

    add_index :tools, :name
    add_index :tools, :tool_type
    add_index :tools, [:workspace_id, :name], unique: true
  end
end
