class CreateEula < ActiveRecord::Migration[7.1]
  def change
    create_table :eulas do |t|
      t.integer :organization_id, null: false
      t.string :file_name
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
