class CreateDataAppSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :data_app_sessions do |t|
      t.string :session_id, null: false
      t.bigint :data_app_id, null: false
      t.integer :workspace_id, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.timestamps
    end
    add_index :data_app_sessions, :session_id, unique: true, name: 'index_data_app_sessions_on_session_id'
    add_index :data_app_sessions, :data_app_id, name: 'index_data_app_sessions_on_data_app_id'
  end
end
