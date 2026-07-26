class AddMetadataToVersions < ActiveRecord::Migration[7.1]
  def up
    add_column :versions, :version_number, :integer
    add_column :versions, :version_description, :text
    add_column :versions, :associations, :jsonb
  end

  def down
    remove_column :versions, :version_number
    remove_column :versions, :version_description
    remove_column :versions, :associations
  end
end