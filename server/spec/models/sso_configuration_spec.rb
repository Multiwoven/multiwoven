# frozen_string_literal: true

require "rails_helper"

RSpec.describe SsoConfiguration, type: :model do
  describe "validations" do
    it { should validate_presence_of(:organization_id) }
    it { should validate_presence_of(:entity_id) }
    it { should validate_presence_of(:acs_url) }
    it { should validate_presence_of(:idp_sso_url) }
    it { should validate_presence_of(:signing_certificate) }
  end

  describe "enum for status" do
    it { should define_enum_for(:status).with_values(%i[disabled enabled]) }
  end

  describe "associations" do
    it { should belong_to(:organization) }
  end
end
