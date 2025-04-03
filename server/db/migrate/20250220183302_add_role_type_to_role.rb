# frozen_string_literal: true
#
class AddRoleTypeToRole < ActiveRecord::Migration[7.1]
  def change
    add_column :roles, :role_type, :integer, default: 0, null: false
  end
end
