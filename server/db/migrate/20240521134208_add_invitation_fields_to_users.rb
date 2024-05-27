class AddInvitationFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :status, :integer, default: 0
  end
end
