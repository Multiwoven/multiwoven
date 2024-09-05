# frozen_string_literal: true

class PopulateCategoryFieldInConnectors < ActiveRecord::Migration[7.1]
  def up
    Connector.find_each do |connector|
      category_name = connector.connector_client.new.meta_data[:data][:category]
      connector.update!(connector_category: category_name) if category_name.present?
    rescue StandardError => e
      Rails.logger.error("Failed to update connector ##{connector.id}: #{e.message}")
    end
  end

  def down
    Connector.find_each do |connector|
      connector.update!(connector_category: "data")
    rescue StandardError => e
      Rails.logger.error("Failed to revert connector ##{connector.id} to 'data': #{e.message}")
    end
  end
end
