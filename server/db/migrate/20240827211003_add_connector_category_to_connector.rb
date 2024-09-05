# frozen_string_literal: true

class AddConnectorCategoryToConnector < ActiveRecord::Migration[7.1]
  def change
    add_column :connectors, :connector_category, :string, null: false, default: "data"
  end
end
