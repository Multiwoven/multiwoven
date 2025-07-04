# frozen_string_literal: true

class CreateSuperAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :super_admins do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name

      t.timestamps
    end

    add_index :super_admins, :email, unique: true
  end
end
