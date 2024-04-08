class AddQueryTypeToConnectors < ActiveRecord::Migration[7.1]
  def up
    add_column :connectors, :query_type, :integer
    change_column_default :connectors, :query_type, 0

    # Set query_type default value based on connector_name
    execute <<-SQL
      UPDATE connectors
      SET query_type = CASE
                         WHEN connector_name = 'SalesforceConsumerGoodsCloud' THEN 1
                         ELSE 0
                       END
    SQL
  end

  def down
    remove_column :connectors, :query_type
  end
end
