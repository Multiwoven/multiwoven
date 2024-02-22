class AddDescriptionToModel < ActiveRecord::Migration[7.1]
  def change
    add_column :models, :description, :string
  end
end
