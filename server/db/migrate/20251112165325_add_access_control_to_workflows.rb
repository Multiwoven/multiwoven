# frozen_string_literal: true

class AddAccessControlToWorkflows < ActiveRecord::Migration[7.1]
  def change
    add_column :workflows, :access_control_enabled, :boolean, default: false, null: false
    add_column :workflows, :access_control, :jsonb, default: {}, null: false
  end
end
