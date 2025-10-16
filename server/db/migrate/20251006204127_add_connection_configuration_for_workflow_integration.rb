class AddConnectionConfigurationForWorkflowIntegration < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:workflow_integrations, :app_type)
      add_column :workflow_integrations, :app_type, :integer, null: false
    end

    unless column_exists?(:workflow_integrations, :connection_configuration)
      add_column :workflow_integrations, :connection_configuration, :jsonb, null: false
    end
  end

  def down
    if column_exists?(:workflow_integrations, :app_type)
      safety_assured { remove_column :workflow_integrations, :app_type }
    end

    if column_exists?(:workflow_integrations, :connection_configuration)
      safety_assured { remove_column :workflow_integrations, :connection_configuration }
    end
  end
end
