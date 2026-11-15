# frozen_string_literal: true

class CreateLlmUsageEvents < ActiveRecord::Migration[7.2]
  TOKEN_COLUMNS = %w[input_tokens output_tokens reasoning_tokens cache_read_tokens cache_write_tokens].freeze

  # No foreign keys: an append only ledger where a cascade would fight retention; the model enforces tenancy.
  def change
    create_table :llm_usage_events do |t|
      t.uuid :request_id, null: false
      t.bigint :organization_id, null: false
      t.bigint :workspace_id, null: false
      t.bigint :user_id
      t.bigint :role_id
      t.integer :source, null: false, default: 0
      t.jsonb :source_ref, null: false, default: {}
      t.bigint :connector_id
      t.string :provider, null: false
      t.string :model, null: false
      t.bigint :input_tokens, null: false, default: 0
      t.bigint :output_tokens, null: false, default: 0
      t.bigint :reasoning_tokens, null: false, default: 0
      t.bigint :cache_read_tokens, null: false, default: 0
      t.bigint :cache_write_tokens, null: false, default: 0
      t.integer :token_count_method, null: false, default: 0
      t.decimal :cost, precision: 18, scale: 10
      t.bigint :pricing_id
      t.integer :status, null: false, default: 0

      t.datetime :created_at, null: false

      t.check_constraint TOKEN_COLUMNS.map { |column| "#{column} >= 0" }.join(" AND "),
                         name: "llm_usage_events_token_counts_non_negative"
      t.check_constraint "cost IS NULL OR cost >= 0",
                         name: "llm_usage_events_cost_non_negative"
      t.index :request_id, unique: true
      t.index %i[workspace_id created_at]
      t.index %i[organization_id created_at]
      t.index %i[workspace_id source created_at],
              name: "index_llm_usage_events_on_workspace_and_source_and_created_at"
    end
  end
end
