# This migration comes from solid_queue (originally 20240813160053)
class MakeNameNotNull < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    SolidQueue::Process.where(name: nil).find_each do |process|
      process.name ||= [ process.kind.downcase, SecureRandom.hex(10) ].join("-")
      process.save!
    end

    add_index :solid_queue_processes, [:name, :supervisor_id], unique: true, algorithm: :concurrently
    safety_assured do
      change_column_null :solid_queue_processes, :name, false
    end
  end

  def down
    remove_index :solid_queue_processes, [ :name, :supervisor_id ]
    change_column :solid_queue_processes, :name, :string, null: true
  end
end
