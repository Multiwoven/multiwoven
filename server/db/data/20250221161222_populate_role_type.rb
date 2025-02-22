# frozen_string_literal: true

class PopulateRoleType < ActiveRecord::Migration[7.1]
  def up
    Role.where(role_name: %w[Admin Viewer Member]).find_each(&:system!)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
