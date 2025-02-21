class ChangeAdditionalRemarkNameInMessageFeedbacks < ActiveRecord::Migration[7.1]
  def change
    safety_assured { rename_column :message_feedbacks, :additional_remark, :additional_remarks }
  end
end
