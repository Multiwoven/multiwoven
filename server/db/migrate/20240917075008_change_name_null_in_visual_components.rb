class ChangeNameNullInVisualComponents < ActiveRecord::Migration[7.1]
  def change
    change_column_null :visual_components, :name, true
  end
end
