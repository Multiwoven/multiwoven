# frozen_string_literal: true

class WorkflowVersionsForExistingWorkflows < ActiveRecord::Migration[7.1]
  def up
    ::Agents::Workflow.find_each do |workflow|
      workflow.paper_trail_event = workflow.status
      snapshot_version = workflow.paper_trail.save_with_version
      snapshot_version.update!(
        whodunnit: workflow.workspace.workspace_users.admins.first.user.email,
        version_description: workflow.description
      ) 
    end
  end

  def down
    ::Agents::Workflow.find_each do |workflow|
      workflow.versions.where(event: ["draft", "published"]).destroy_all
    end
  end
end
