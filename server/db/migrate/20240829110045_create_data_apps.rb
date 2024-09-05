class CreateDataApps < ActiveRecord::Migration[7.1]
  def change
    create_table :data_apps do |t|
      t.string :name, null: false
      t.integer :status, null: false
      t.integer :workspace_id, null: false
      t.text :description
      t.json :meta_data

      t.timestamps
    end
  end
end
