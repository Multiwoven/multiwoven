class SetDataForRenderingTypeInDataApps < ActiveRecord::Migration[7.1]
  def change
    DataApp.find_each do |da|
      rendering_type = da.meta_data.try(:[],"rendering_type") || "embed"
      da.update_column(:rendering_type, rendering_type)
    end
  end
end
