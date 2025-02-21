# frozen_string_literal: true

class SsoConfiguration < ApplicationRecord
  validates :organization_id, presence: true
  validates :status, presence: true
  validates :entity_id, presence: true
  validates :acs_url, presence: true
  validates :idp_sso_url, presence: true
  validates :signing_certificate, presence: true

  enum :status, %i[disabled enabled]

  belongs_to :organization
end
