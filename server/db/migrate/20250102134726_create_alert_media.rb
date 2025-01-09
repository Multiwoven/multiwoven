class CreateAlertMedia < ActiveRecord::Migration[7.1]
  def change
    create_table :alert_media do |t|
      t.string :name
      t.integer :platform

      t.timestamps
    end
  end
end
