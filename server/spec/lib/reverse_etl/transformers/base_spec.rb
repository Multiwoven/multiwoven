# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Transformers::Base do
  describe "#transform" do
    it 'raises a "Not implemented" error' do
      base_extractor = ReverseEtl::Transformers::Base.new
      expect { base_extractor.transform(nil, nil) }.to raise_error(RuntimeError, "Not implemented")
    end
  end
end
