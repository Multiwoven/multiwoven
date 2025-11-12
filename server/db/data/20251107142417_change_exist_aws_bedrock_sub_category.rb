class ChangeExistAwsBedrockSubCategory < ActiveRecord::Migration[7.1]
  def up
    Connector.where(connector_name: "AwsBedrockModel", connector_sub_category: "AI_ML Service").update_all(connector_sub_category: "LLM")
  end

  def down
    Connector.where(connector_name: "AwsBedrockModel", connector_sub_category: "LLM").update_all(connector_sub_category: "AI_ML Service")
  end
end
