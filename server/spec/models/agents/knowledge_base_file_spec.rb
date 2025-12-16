# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::KnowledgeBaseFile, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:size) }
    it { should validate_presence_of(:upload_status) }
  end

  describe "associations" do
    it { should belong_to(:knowledge_base) }
  end

  describe "file attachments" do
    it { should have_one_attached(:file) }
  end
end
