class AddOrganizationIdToRole < ActiveRecord::Migration[7.1]
  def change
    add_column :roles, :organization_id, :integer, null: true
  end
end
