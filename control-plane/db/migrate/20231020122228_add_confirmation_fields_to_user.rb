# frozen_string_literal: true

class AddConfirmationFieldsToUser < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :confirmation_code
      t.datetime :confirmed_at
    end
  end
end
