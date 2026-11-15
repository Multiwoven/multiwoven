# frozen_string_literal: true

# LedgerScope narrows by provider and by an id inside source_ref; neither is otherwise indexed.
class IndexLlmUsageEventsForReconciliation < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :llm_usage_events,
              "workspace_id, lower(provider), created_at",
              name: "index_llm_usage_events_on_workspace_and_lower_provider",
              algorithm: :concurrently

    add_index :llm_usage_events,
              "workspace_id, (source_ref ->> 'workflow_id'), created_at",
              name: "index_llm_usage_events_on_workspace_and_workflow_ref",
              where: "source_ref ? 'workflow_id'",
              algorithm: :concurrently

    add_index :llm_usage_events,
              "workspace_id, (source_ref ->> 'data_app_id'), created_at",
              name: "index_llm_usage_events_on_workspace_and_data_app_ref",
              where: "source_ref ? 'data_app_id'",
              algorithm: :concurrently
  end
end
