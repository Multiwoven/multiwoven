class AddEulaAcceptedToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  def change
    add_column :users, :eula_accepted, :boolean, default: false, null: false
    add_column :users, :eula_enabled, :boolean, default: false, null: false
  end
end
