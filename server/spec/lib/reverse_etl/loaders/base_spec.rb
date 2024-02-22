# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Loaders::Base do
  describe "#transform" do
    it 'raises a "Not implemented" error' do
      base_extractor = ReverseEtl::Loaders::Base.new
      expect { base_extractor.write(nil) }.to raise_error(RuntimeError, "Not implemented")
    end
  end
end
