class RemoveTemplateToWorkflows < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :workflows, :workflow_type }
  end
end
