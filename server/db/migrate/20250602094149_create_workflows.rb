# frozen_string_literal: true

class CreateWorkflows < ActiveRecord::Migration[7.1]
  def change
    create_table :workflows, id: :uuid do |t|
      t.integer :workspace_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :status
      t.integer :trigger_type
      t.jsonb :configuration, default: {}
      t.string :token

      t.timestamps
    end

    add_foreign_key :workflows, :workspaces, validate: false
  end
end
