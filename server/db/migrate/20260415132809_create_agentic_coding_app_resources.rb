# frozen_string_literal: true

class CreateAgenticCodingAppResources < ActiveRecord::Migration[7.1]
  def change
    create_table :agentic_coding_app_resources, id: :uuid do |t|
      t.references :agentic_coding_app, type: :uuid, null: false, foreign_key: true
      t.string :resource_type, null: false
      t.string :resource_id
      t.jsonb :credentials, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false
      t.string :status, null: false, default: "provisioning"
      t.timestamps
    end

    add_index :agentic_coding_app_resources, %i[agentic_coding_app_id resource_type],
              unique: true, name: "idx_app_resources_on_app_id_and_type"
    add_index :agentic_coding_app_resources, :resource_type
  end
end
