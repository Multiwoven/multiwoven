# frozen_string_literal: true

class AddNeonDeployedAtToAgenticCodingDeployments < ActiveRecord::Migration[7.1]
  def change
    add_column :agentic_coding_deployments, :neon_deployed_at, :datetime, null: true
  end
end
