class AddEulaAcceptedAtToUser < ActiveRecord::Migration[7.1]
  def change
    # Check if the column already exists before trying to add it
    unless column_exists?(:users, :eula_accepted_at)
      add_column :users, :eula_accepted_at, :datetime, default: nil
    end
  end
end
