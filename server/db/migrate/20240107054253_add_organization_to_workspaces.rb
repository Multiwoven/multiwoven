class AddOrganizationToWorkspaces < ActiveRecord::Migration[7.1]
  def change
    add_reference :workspaces, :organization, foreign_key: true
  end
end
