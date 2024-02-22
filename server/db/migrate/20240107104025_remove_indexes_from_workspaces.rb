class RemoveIndexesFromWorkspaces < ActiveRecord::Migration[7.1]
  def change
    remove_index :workspaces, name: 'index_workspaces_on_name'
    remove_index :workspaces, name: 'index_workspaces_on_slug'
  end
end
