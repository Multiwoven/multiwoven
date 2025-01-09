class AddLastRunAtToAlert < ActiveRecord::Migration[7.1]
  def change
    add_column :alerts, :last_run_at, :datetime
  end
end
