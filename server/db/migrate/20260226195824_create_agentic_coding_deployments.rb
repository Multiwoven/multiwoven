class CreateAgenticCodingDeployments < ActiveRecord::Migration[7.1]
  def change
    create_table :agentic_coding_deployments, id: :uuid do |t|
      t.references :agentic_coding_app, null: false, foreign_key: { to_table: :agentic_coding_apps }, type: :uuid
      t.references :agentic_coding_session, null: false, foreign_key: { to_table: :agentic_coding_sessions }, type: :uuid
      t.references :workspace, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.string :deploy_url
      t.string :deploy_target
      t.string :commit_sha
      t.string :version_tag
      t.jsonb :deploy_metadata
      t.text :error_message

      t.timestamps
    end
  end
end
