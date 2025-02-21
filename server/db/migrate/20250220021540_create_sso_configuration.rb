class CreateSsoConfiguration < ActiveRecord::Migration[7.1]
  def change
    create_table :sso_configurations do |t|
      t.integer :organization_id
      t.integer :status, default: 1
      t.string :entity_id
      t.string :acs_url
      t.string :idp_sso_url
      t.string :signing_certificate

      t.timestamps
    end
  end
end
