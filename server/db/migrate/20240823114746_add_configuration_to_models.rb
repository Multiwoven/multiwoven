class AddConfigurationToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :models, :configuration, :jsonb
  end
end
