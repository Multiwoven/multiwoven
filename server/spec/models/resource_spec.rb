# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resource, type: :model do
  describe "validations" do
    it { should validate_presence_of(:resources_name) }
  end
end
