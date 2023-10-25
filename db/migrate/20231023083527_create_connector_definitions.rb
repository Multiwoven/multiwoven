class CreateConnectorDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :connector_definitions do |t|
      t.integer :connector_type
      t.jsonb :spec
      t.integer :source_type
      t.jsonb :meta_data

      t.timestamps
    end
  end
end
