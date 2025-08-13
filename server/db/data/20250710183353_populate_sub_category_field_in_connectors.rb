class PopulateSubCategoryFieldInConnectors < ActiveRecord::Migration[7.1]
  def up
    Connector.find_each do |connector|
      sub_category_name = connector.connector_client.new.meta_data[:data][:sub_category]
      sub_category_name = "Vector Database" if connector.configuration["data_type"] == "vector"
      connector.update!(connector_sub_category: sub_category_name) if sub_category_name.present?
    rescue StandardError => e
      Rails.logger.error("Failed to update connector ##{connector.id}: #{e.message}")
    end
  end

  def down
    Connector.find_each do |connector|
      connector.update!(connector_sub_category: "database")
    rescue StandardError => e
      Rails.logger.error("Failed to revert connector ##{connector.id} to 'data': #{e.message}")
    end
  end
end
