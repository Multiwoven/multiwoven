class CreateHostedDataStore < ActiveRecord::Migration[7.1]
  def up
    create_table :hosted_data_stores do |t|
      t.string :name
      t.integer :workspace_id
      t.integer :database_type
      t.text :description
      t.integer :state
      t.integer :source_connector_id
      t.integer :destination_connector_id
      t.string :template_id, null: false

      t.timestamps
    end

    # Add the foreign key only if the parent table exists
    if table_exists?(:workspaces)
      add_foreign_key :hosted_data_stores, :workspaces, validate: false
    end
  end

  def down
    remove_foreign_key :hosted_data_stores, :workspaces rescue nil
    drop_table :hosted_data_stores, if_exists: true
  end
end
