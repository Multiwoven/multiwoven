# frozen_string_literal: true

class AddResources < ActiveRecord::Migration[7.1]
  def up
    resources_data = [
      {
        resources_name: "workspace",
        permissions: %w[create read update delete]
      },
      {
        resources_name: "sync",
        permissions: %w[create read update delete configuration]
      },
      {
        resources_name: "model",
        permissions: %w[create read update delete]
      },
      {
        resources_name: "connector",
        permissions: %w[create read update delete discover query_source]
      },
      {
        resources_name: "connector_definition",
        permissions: %w[read check_connection]
      },
      {
        resources_name: "report",
        permissions: ["read"]
      },
      {
        resources_name: "sync_run",
        permissions: ["read"]
      },
      {
        resources_name: "sync_record",
        permissions: ["read"]
      },
      {
        resources_name: "user",
        permissions: ["read"]
      }
    ]

    resources_data.each do |resource_data|
      resource = Resource.create!(
        resources_name: resource_data[:resources_name],
        permissions: resource_data[:permissions]
      )
      puts "Resource '#{resource.resources_name}' created successfully with permissions: #{resource.permissions}"
    end
  end

  def down
    Resource.destroy_all
  end
end
