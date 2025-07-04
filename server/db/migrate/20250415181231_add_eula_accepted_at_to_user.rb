class AddEulaAcceptedAtToUser < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      # Check if the column exists first
      if !column_exists?(:users, :eula_accepted_at)
        add_column :users, :eula_accepted_at, :datetime, default: nil
      else
        say "Column eula_accepted_at already exists, skipping"
      end
    end
  end

  def down
    safety_assured do
      remove_column :users, :eula_accepted_at if column_exists?(:users, :eula_accepted_at)
    end
  end
end
