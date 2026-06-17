# frozen_string_literal: true

class EncryptAgenticCodingAppResourcesCredentials < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      change_column :agentic_coding_app_resources, :credentials, :text, default: nil,
                                                                        using: "credentials::text"
    end
  end

  def down
    safety_assured do
      change_column :agentic_coding_app_resources, :credentials, :jsonb, default: {},
                                                                         using: "credentials::jsonb"
    end
  end
end
