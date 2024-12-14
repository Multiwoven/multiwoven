class CreateCustVisualCompntFile < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_visual_component_files do |t|
      t.string :file_name
      t.integer :workspace_id, null: false

      t.timestamps
    end
  end
end
