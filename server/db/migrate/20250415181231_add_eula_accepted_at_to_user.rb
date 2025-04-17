class AddEulaAcceptedAtToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :eula_accepted_at, :datetime, default: nil
  end
end
