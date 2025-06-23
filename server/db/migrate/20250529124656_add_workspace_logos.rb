class AddWorkspaceLogos < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:workspaces, :workspace_logo_filename)
      add_column :workspaces, :workspace_logo_filename, :string
    end
  end

  def down
    if column_exists?(:workspaces, :workspace_logo_filename)
      remove_column :workspaces, :workspace_logo_filename
    end
  end
end
