class AddSessionIdAndSessionCountToFeedbacksAndVisualComponents < ActiveRecord::Migration[7.1]
  def up
    add_column :feedbacks, :session_id, :string, default: nil, null: true
    add_column :visual_components, :session_count, :integer, default: 0
  end

  def down
    remove_column :feedbacks, :session_id
    remove_column :visual_components, :session_count
  end
end
