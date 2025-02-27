# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:data_app_session) }
    it { should belong_to(:visual_component) }
  end

  describe "enum for role" do
    it { should define_enum_for(:role).with_values(%i[user assistant]) }
  end

  describe "validations" do
    it { should validate_presence_of(:content) }
  end
end
