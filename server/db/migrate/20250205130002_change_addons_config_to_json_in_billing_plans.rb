class ChangeAddonsConfigToJsonInBillingPlans < ActiveRecord::Migration[7.1]
  def change
    safety_assured do 
      add_column :billing_plans, :addons, :jsonb, default: {}, null: false
      remove_column :billing_plans, :addons_config
    end
  end
end
