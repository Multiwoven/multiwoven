class CreateLlmUsageLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :llm_usage_logs do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :workflow_run, null: false,
                   foreign_key: { to_table: :workflow_runs }
      t.string :component_id, null: false
      t.string :connector_id, null: false
      t.string :prompt_hash, null: false, index: true
      t.integer :estimated_input_tokens, null: false
      t.integer :estimated_output_tokens, null: false
      t.string :selected_model, null: false

      t.timestamps
    end

    add_index :llm_usage_logs, :created_at
    add_index :llm_usage_logs, :component_id
    add_index :llm_usage_logs, :selected_model

    add_foreign_key :llm_usage_logs, :components, column: :component_id, primary_key: :id, validate: false
  end
end
