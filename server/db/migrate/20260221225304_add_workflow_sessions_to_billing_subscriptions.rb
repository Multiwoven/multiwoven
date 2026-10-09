class AddWorkflowSessionsToBillingSubscriptions < ActiveRecord::Migration[7.1]
  def up
    add_column :billing_subscriptions, :workflow_sessions, :integer, default: 0
  end

  def down
    remove_column :billing_subscriptions, :workflow_sessions
  end
end
