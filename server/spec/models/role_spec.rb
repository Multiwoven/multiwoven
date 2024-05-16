# frozen_string_literal: true

require "rails_helper"

RSpec.describe Role, type: :model do
  describe "validations" do
    it { should validate_presence_of(:role_name) }
    it { should validate_presence_of(:policies) }
  end
end
