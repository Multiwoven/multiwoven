class CreateSyncRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_runs do |t|
      t.integer :sync_id
      t.integer :status
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :total_rows
      t.integer :successful_rows
      t.integer :failed_rows
      t.text :error

      t.timestamps
    end
  end
end
