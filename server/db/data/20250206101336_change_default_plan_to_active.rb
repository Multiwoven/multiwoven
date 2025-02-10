# frozen_string_literal: true

class ChangeDefaultPlanToActive < ActiveRecord::Migration[7.1]
  def up
    plan = Billing::Plan.find_by(name: "Starter")
    plan.active!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
