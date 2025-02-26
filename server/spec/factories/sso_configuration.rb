# frozen_string_literal: true

FactoryBot.define do
  factory :sso_configuration do
    association :organization
    status { 1 }
    entity_id { "https://example.com/entity" }
    acs_url { "https://example.com/acs" }
    idp_sso_url { "https://example.com/sso" }
    signing_certificate { "-----BEGIN CERTIFICATE-----\nMIIBIjANBgkqh...\n-----END CERTIFICATE-----" }
  end
end
