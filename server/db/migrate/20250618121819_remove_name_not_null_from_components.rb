class RemoveNameNotNullFromComponents < ActiveRecord::Migration[7.1]
  def change
    safety_assured { change_column_null :components, :name, true }
  end
end
