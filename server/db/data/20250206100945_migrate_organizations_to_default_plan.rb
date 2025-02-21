# frozen_string_literal: true

class MigrateOrganizationsToDefaultPlan < ActiveRecord::Migration[7.1]
  def up
    plan = Billing::Plan.find_by(name: "Starter")
    organizations = Organization.all

    organizations.each do |org|
      Billing::Subscription.create!(
        organization_id: org.id,
        plan_id: plan.id,
        status: 1,
        data_app_sessions: 10_000,
        feedback_count: 1_000,
        rows_synced: 100_000,
        addons_usage: {}
      )
      puts "Subscription created for Organization ID: #{org.id}"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
