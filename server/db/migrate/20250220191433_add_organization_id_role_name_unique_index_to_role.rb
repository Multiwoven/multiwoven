class AddOrganizationIdRoleNameUniqueIndexToRole < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  def change
    add_index :roles, [:organization_id, :role_name], unique: true, where: "organization_id IS NOT NULL", algorithm: :concurrently
  end
end
