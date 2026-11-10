# frozen_string_literal: true

# ActiveRecord Encryption for sensitive attributes (e.g. AppResource.credentials).
# Set AR_ENCRYPTION_PRIMARY_KEY env var before first deploy. Do NOT change after data is encrypted.
secret = ENV["AR_ENCRYPTION_PRIMARY_KEY"].presence || Rails.application.secret_key_base

Rails.application.config.active_record.encryption.primary_key = secret
Rails.application.config.active_record.encryption.deterministic_key =
  Digest::SHA256.hexdigest("ar-encryption:deterministic:#{secret}")
Rails.application.config.active_record.encryption.key_derivation_salt =
  Digest::SHA256.hexdigest("ar-encryption:salt:#{secret}")
Rails.application.config.active_record.encryption.support_unencrypted_data = true
