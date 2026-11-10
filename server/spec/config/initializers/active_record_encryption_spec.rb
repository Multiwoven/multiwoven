# frozen_string_literal: true

require "rails_helper"

RSpec.describe "active_record_encryption initializer" do
  let(:initializer) { Rails.root.join("config/initializers/active_record_encryption.rb") }
  let(:encryption_config) { Rails.application.config.active_record.encryption }

  around do |example|
    original_primary_key = encryption_config.primary_key
    original_deterministic_key = encryption_config.deterministic_key
    original_salt = encryption_config.key_derivation_salt
    original_env = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", nil)
    example.run
  ensure
    original_env.nil? ? ENV.delete("AR_ENCRYPTION_PRIMARY_KEY") : ENV["AR_ENCRYPTION_PRIMARY_KEY"] = original_env
    load initializer
    encryption_config.primary_key = original_primary_key
    encryption_config.deterministic_key = original_deterministic_key
    encryption_config.key_derivation_salt = original_salt
  end

  it "uses AR_ENCRYPTION_PRIMARY_KEY when it is set" do
    ENV["AR_ENCRYPTION_PRIMARY_KEY"] = "custom-primary-key"
    load initializer

    expect(encryption_config.primary_key).to eq("custom-primary-key")
  end

  it "falls back to secret_key_base when AR_ENCRYPTION_PRIMARY_KEY is blank" do
    ENV["AR_ENCRYPTION_PRIMARY_KEY"] = ""
    load initializer

    expect(encryption_config.primary_key).to eq(Rails.application.secret_key_base)
  end

  it "falls back to secret_key_base when AR_ENCRYPTION_PRIMARY_KEY is unset" do
    ENV.delete("AR_ENCRYPTION_PRIMARY_KEY")
    load initializer

    expect(encryption_config.primary_key).to eq(Rails.application.secret_key_base)
  end
end
