class CreateAgenticCodingPrompts < ActiveRecord::Migration[7.1]
  def change
    create_table :agentic_coding_prompts, id: :uuid do |t|
      t.references :agentic_coding_app, null: false, foreign_key: { to_table: :agentic_coding_apps }, type: :uuid
      t.references :agentic_coding_session, null: false, foreign_key: { to_table: :agentic_coding_sessions }, type: :uuid
      t.integer :role
      t.text :content
      t.integer :status, null: false, default: 0
      t.text :response_text
      t.string :agent_mode

      t.timestamps
    end
  end
end
