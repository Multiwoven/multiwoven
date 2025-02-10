class RenameBillingPlanIdToPlanIdInBillingSubscriptions < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      rename_column :billing_subscriptions, :billing_plan_id, :plan_id
    end
  end
end
