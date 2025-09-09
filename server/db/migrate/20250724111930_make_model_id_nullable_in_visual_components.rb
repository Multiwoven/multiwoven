class MakeModelIdNullableInVisualComponents < ActiveRecord::Migration[7.1]
  def change
    change_column_null :visual_components, :model_id, true
  end
end
