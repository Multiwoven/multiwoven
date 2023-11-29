# frozen_string_literal: true

class CreateWorkspaces < ActiveRecord::Migration[7.1]
  def change
    create_table :workspaces do |t|
      t.string :name
      t.string :slug
      t.string :status
      t.string :api_key

      t.timestamps
    end
  end
end
