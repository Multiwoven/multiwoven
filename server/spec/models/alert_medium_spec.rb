# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlertMedium, type: :model do
  describe "validations" do
    it { should validate_presence_of(:platform) }
  end
end
