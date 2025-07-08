class AddDataAndJsonToComponents < ActiveRecord::Migration[7.1]
  def up
    add_column :components, :data, :jsonb, default: {}, null: false
    add_column :components, :component_category, :integer, default: 0, null: false
  end

  def down
    remove_column :components, :data
    remove_column :components, :component_category
  end
end
