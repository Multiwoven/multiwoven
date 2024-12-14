# frozen_string_literal: true

class AddCatalogAndScheduleSyncResources < ActiveRecord::Migration[7.1]
  def up
    new_resources_data = [
      {
        resources_name: "catalog",
        permissions: %w[create read update delete]
      },
      {
        resources_name: "schedule_sync",
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
    Resource.where(resources_name: %w[catalog schedule_sync]).destroy_all
  end
end
