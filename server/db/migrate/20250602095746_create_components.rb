# frozen_string_literal: true

class CreateComponents < ActiveRecord::Migration[7.1]
  def change
    create_table :components, id: false do |t|
      t.string :id, primary_key: true
      t.integer :workspace_id, null: false
      t.uuid :workflow_id, null: false
      t.string :name, null: false
      t.integer :component_type, null: false
      t.jsonb :configuration, null: false
      t.jsonb :position, default: {}

      t.timestamps
    end

    add_foreign_key :components, :workflows, validate: false
    add_foreign_key :components, :workspaces, validate: false
  end
end
