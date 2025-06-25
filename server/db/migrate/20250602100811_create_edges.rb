# frozen_string_literal: true

class CreateEdges < ActiveRecord::Migration[7.1]
  def change
    drop_table :edges, if_exists: true

    create_table :edges, id: :string do |t|
      t.uuid :workflow_id, null: false
      t.integer :workspace_id, null: false
      t.string :source_component_id, null: false
      t.string :target_component_id, null: false
      t.jsonb :source_handle, null: false
      t.jsonb :target_handle, null: false

      t.timestamps
    end

    add_foreign_key :edges, :workflows, column: :workflow_id, validate: false
    add_foreign_key :edges, :workspaces, column: :workspace_id, validate: false
    add_foreign_key :edges, :components, column: :source_component_id, primary_key: :id, validate: false
    add_foreign_key :edges, :components, column: :target_component_id, primary_key: :id, validate: false
  end
end
