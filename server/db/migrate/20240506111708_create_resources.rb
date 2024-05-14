class CreateResources < ActiveRecord::Migration[7.1]
  def change
    create_table :resources do |t|
      t.string :resources_name
      t.text :permissions, array: true, default: []

      t.timestamps
    end
  end
end
