# frozen_string_literal: true

class AddPartialUniqueIndexOnAgenticCodingAppResources < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :agentic_coding_app_resources,
              %i[agentic_coding_app_id resource_type],
              unique: true,
              where: "status <> 'deleted'",
              name: "idx_agentic_app_resources_active_type_per_app",
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :agentic_coding_app_resources,
                 name: "idx_app_resources_on_app_id_and_type",
                 algorithm: :concurrently,
                 if_exists: true
  end

  def down
    add_index :agentic_coding_app_resources,
              %i[agentic_coding_app_id resource_type],
              unique: true,
              name: "idx_app_resources_on_app_id_and_type",
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :agentic_coding_app_resources,
                 name: "idx_agentic_app_resources_active_type_per_app",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
