# frozen_string_literal: true

require "rails_helper"

RSpec.describe KnowledgeBase, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:knowledge_base_type) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:embedding_config) }
    it { should validate_presence_of(:storage_config) }
  end

  describe "enum for knowledge_base_type" do
    it { should define_enum_for(:knowledge_base_type).with_values(%i[vector_store semantic_data_model]) }
  end

  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:hosted_data_store).optional }
    it { should belong_to(:source_connector).class_name("Connector").optional }
    it { should belong_to(:destination_connector).class_name("Connector").optional }
  end
end
