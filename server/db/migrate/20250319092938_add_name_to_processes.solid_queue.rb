# This migration comes from solid_queue (originally 20240811173327)
class AddNameToProcesses < ActiveRecord::Migration[7.1]
  def change
    add_column :solid_queue_processes, :name, :string
  end
end
