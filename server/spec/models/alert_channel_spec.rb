# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlertChannel, type: :model do
  describe "associations" do
    it { should belong_to(:alert) }
  end
end
