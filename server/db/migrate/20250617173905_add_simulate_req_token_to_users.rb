# frozen_string_literal: true

class AddSimulateReqTokenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :simulate_req_token, :string
  end
end
