class AddOrganizationLogos < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:organizations, :organization_logo_filename)
      add_column :organizations, :organization_logo_filename, :string
    end
  end

  def down
    if column_exists?(:organizations, :organization_logo_filename)
      remove_column :organizations, :organization_logo_filename
    end
  end
end
