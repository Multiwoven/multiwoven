class AddCronExpressionToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :cron_expression, :string
  end
end
