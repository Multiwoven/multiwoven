class CreateAgenticCodingApps < ActiveRecord::Migration[7.1]
  def change
    create_table :agentic_coding_apps, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
