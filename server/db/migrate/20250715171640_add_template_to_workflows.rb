class AddTemplateToWorkflows < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:workflows, :workflow_type)
      add_column :workflows, :workflow_type, :integer, null: false, default: 0
    end
  end

  def down
    if column_exists?(:workflows, :workflow_type)
      remove_column :workflows, :workflow_type
    end
  end
end
