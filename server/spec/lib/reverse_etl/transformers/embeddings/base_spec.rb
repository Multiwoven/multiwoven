# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Transformers::Embeddings::Base, type: :model do
  let(:embedding_config) { double("embedding_config") }
  let(:base_embedding) { ReverseEtl::Transformers::Embeddings::Base.new(embedding_config) }

  describe "#generate_embedding" do
    it "raises a NotImplementedError" do
      expect { base_embedding.generate_embedding("sample text") }
        .to raise_error(NotImplementedError, "This method must be implemented in a subclass")
    end
  end
end
