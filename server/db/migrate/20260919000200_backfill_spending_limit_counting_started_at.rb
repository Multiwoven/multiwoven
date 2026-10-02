# frozen_string_literal: true

class BackfillSpendingLimitCountingStartedAt < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  # safety_assured: a batched, index-driven UPDATE outside a DDL transaction takes no long lock.
  def up
    safety_assured do
      loop do
        moved = execute(<<~SQL.squish).cmd_tuples
          UPDATE spending_limits SET counting_started_at = created_at
          WHERE id IN (
            SELECT id FROM spending_limits WHERE counting_started_at <> created_at LIMIT #{BATCH_SIZE}
          )
        SQL
        break if moved.zero?
      end
    end
  end

  # The pre-backfill values were the deploy timestamp and carry no information.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
