# frozen_string_literal: true

class AddWorkflowResources < ActiveRecord::Migration[7.1]
  def up
    new_resources_data = [
      {
        resources_name: "workflow",
        permissions: %w[create read update delete]
      }
    ]

    new_resources_data.each do |resource_data|
      resource = Resource.create!(
        resources_name: resource_data[:resources_name],
        permissions: resource_data[:permissions]
      )
      puts "Resource '#{resource.resources_name}' created successfully with permissions: #{resource.permissions}"
    end
  end

  def down
    Resource.where(resources_name: %w[workflow]).destroy_all
  end
end
