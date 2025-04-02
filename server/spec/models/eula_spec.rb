# frozen_string_literal: true

require "rails_helper"

RSpec.describe Eula, type: :model do
  describe "validations" do
    it { should validate_presence_of(:organization_id) }
    it { should validate_presence_of(:status) }
  end

  describe "enum for status" do
    it { should define_enum_for(:status).with_values(%i[disabled enabled]) }
  end

  describe "associations" do
    it { should belong_to(:organization) }
    it { should have_one_attached(:file) }
  end
end
