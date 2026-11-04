# frozen_string_literal: true

class CreateSpendingLimits < ActiveRecord::Migration[7.2]
  # Indexes live inside create_table: nothing to lock on a new table, which also keeps strong_migrations quiet.
  def change
    create_table :spending_limits do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.integer :level, null: false, default: 0
      t.string :name, null: false
      t.integer :scope_type, null: false, default: 0
      t.string :scope_ids, array: true, null: false, default: []
      t.string :providers, array: true, null: false, default: []
      t.string :models, array: true, null: false, default: []
      t.integer :limit_type, null: false, default: 0
      t.decimal :cost_limit, precision: 14, scale: 4
      t.bigint :token_limit
      t.integer :period, null: false, default: 0
      t.integer :alert_thresholds, array: true, null: false, default: [80, 90]
      t.integer :action_on_exhaust, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps

      t.check_constraint "cost_limit IS NULL OR cost_limit > 0",
                         name: "spending_limits_cost_limit_positive"
      t.check_constraint "token_limit IS NULL OR token_limit > 0",
                         name: "spending_limits_token_limit_positive"
      t.check_constraint "(limit_type = 0 AND cost_limit IS NOT NULL) " \
                         "OR (limit_type = 1 AND token_limit IS NOT NULL) " \
                         "OR (limit_type = 2 AND cost_limit IS NOT NULL AND token_limit IS NOT NULL)",
                         name: "spending_limits_cap_matches_limit_type"
      t.index %i[workspace_id name], unique: true,
                                     name: "index_spending_limits_on_workspace_id_and_name"
      t.index :workspace_id, unique: true, where: "level = 1",
                             name: "index_spending_limits_one_allocation_per_workspace"
    end
  end
end
