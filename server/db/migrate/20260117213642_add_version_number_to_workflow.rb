class AddVersionNumberToWorkflow < ActiveRecord::Migration[7.1]
  def up
    add_column :workflows, :version_number, :integer, default: 1
  end

  def down
    remove_column :workflows, :version_number
  end
end