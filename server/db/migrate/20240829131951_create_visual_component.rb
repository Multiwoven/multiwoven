class CreateVisualComponent < ActiveRecord::Migration[7.1]
  def change
    create_table :visual_components do |t|
      t.integer :component_type, null: false
      t.string :name, null: false
      t.integer :workspace_id, null: false
      t.integer :data_app_id, null: false
      t.integer :model_id, null: false
      t.jsonb :properties
      t.jsonb :feedback_config

      t.timestamps
    end
  end
end
