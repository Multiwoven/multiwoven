# frozen_string_literal: true

class AddUniqueIndexesToWorkspaces < ActiveRecord::Migration[7.1]
  def change
    add_index :workspaces, :name, unique: true
    add_index :workspaces, :slug, unique: true
  end
end
