class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :role_name
      t.string :role_desc
      t.jsonb :policies, default: {}

      t.timestamps
    end
  end
end
