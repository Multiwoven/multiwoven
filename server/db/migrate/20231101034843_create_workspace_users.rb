# frozen_string_literal: true

class CreateWorkspaceUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :workspace_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workspace, null: true, foreign_key: { on_delete: :nullify }
      t.string :role, null: false # admin, member, viewer, etc.
      t.timestamps
    end
  end
end
