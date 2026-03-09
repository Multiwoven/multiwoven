class CreateAgenticCodingSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :agentic_coding_sessions, id: :uuid do |t|
      t.references :agentic_coding_app, null: false, foreign_key: { to_table: :agentic_coding_apps }, type: :uuid
      t.references :workspace, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.integer :status, null: false, default: 0
      t.string :sandbox_id
      t.string :coding_agent_session_id
      t.string :preview_url
      t.datetime :last_active_at
      t.datetime :suspended_at

      t.timestamps
    end
  end
end
