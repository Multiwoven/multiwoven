class AddFeedbacksCountToDataApps < ActiveRecord::Migration[7.1]
  def self.up
    add_column :data_apps, :feedbacks_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :data_apps, :feedbacks_count
  end
end
