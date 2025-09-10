class AssignConfigurableFromModel < ActiveRecord::Migration[7.1]
  def self.up
    VisualComponent.where(configurable_type: [nil, ''], configurable_id: nil).find_each do |vc|
      if vc.model_id.present?
        vc.update_columns(
          configurable_type: 'Model',
          configurable_id: vc.model_id
        )
      end
    end
  end

  def self.down
    VisualComponent.where(configurable_type: 'Model').find_each do |vc|
      vc.update_columns(
        model_id: vc.configurable_id,
        configurable_type: nil,
        configurable_id: nil
      )
    end
  end
end
