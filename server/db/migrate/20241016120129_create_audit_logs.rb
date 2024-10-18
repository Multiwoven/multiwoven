class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.integer :user_id
      t.string :action, null: false
      t.string :resource_type, null: false
      t.integer :resource_id
      t.string :resource
      t.integer :workspace_id
      t.json :metadata

      t.timestamps
    end
  end
end
