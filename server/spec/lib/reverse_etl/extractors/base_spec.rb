# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::Base do
  describe "#read" do
    it 'raises a "Not implemented" error' do
      base_extractor = ReverseEtl::Extractors::Base.new
      expect { base_extractor.read(nil) }.to raise_error(RuntimeError, "Not implemented")
    end
  end
end
