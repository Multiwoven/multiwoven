class AddAdditionalRemarksToFeedbacks < ActiveRecord::Migration[7.1]
  def change
    add_column :feedbacks, :additional_remarks, :jsonb
  end
end
