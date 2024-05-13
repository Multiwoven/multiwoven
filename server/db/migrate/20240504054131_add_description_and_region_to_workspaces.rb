class AddDescriptionAndRegionToWorkspaces < ActiveRecord::Migration[7.1]
  def change
    add_column :workspaces, :description, :text
    add_column :workspaces, :region, :string
  end
end
