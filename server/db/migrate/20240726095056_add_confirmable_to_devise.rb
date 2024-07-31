class AddConfirmableToDevise < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmation_sent_at, :datetime

    safety_assured { add_index :users, :confirmation_token, unique: true }
  end
end
