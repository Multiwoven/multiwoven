class AddLogoToAlertMedium < ActiveRecord::Migration[7.1]
  def change
    add_column :alert_media, :logo, :string
  end
end
