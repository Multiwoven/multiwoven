class CreateRemoteCodeExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :remote_code_executions do |t|
      t.integer :workflow_run_id
      t.integer :workspace_id, null: false
      t.string :component_id
      t.integer :provider
      t.integer :mode
      t.integer :status
      t.text :output
      t.text :error_message
      t.text :stdout
      t.integer :execution_time_ms
      t.integer :memory_used_mb
      t.integer :cpu_time_ms
      t.integer :billed_duration_ms
      t.datetime :start_time
      t.datetime :end_time
      t.string :invocation_id, limit: 100

      t.timestamps
    end
  end
end
