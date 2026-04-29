# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::AppResource, type: :model do
  context "validations" do
    it { should belong_to(:agentic_coding_app).class_name("AgenticCoding::App") }
    it { should validate_presence_of(:resource_type) }
    it { should validate_inclusion_of(:status).in_array(%w[provisioning provisioned failed deleted]) }
  end

  context "uniqueness" do
    subject { create(:agentic_coding_app_resource) }

    it { should validate_uniqueness_of(:resource_type).scoped_to(:agentic_coding_app_id) }
  end

  describe "resource types" do
    let(:app) { create(:agentic_coding_app) }

    it "creates a neon_database resource" do
      resource = create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect(resource.resource_type).to eq("neon_database")
      expect(resource.status).to eq("provisioned")
      expect(resource.credentials).to have_key("database_url")
    end

    it "creates an s3_storage resource" do
      resource = create(:agentic_coding_app_resource, :s3_storage, agentic_coding_app: app)
      expect(resource.resource_type).to eq("s3_storage")
      expect(resource.credentials).to have_key("endpoint")
      expect(resource.credentials).to have_key("access_key")
    end

    it "prevents duplicate resource types per app" do
      create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      duplicate = build(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:resource_type]).to include("has already been taken")
    end

    it "allows same resource type on different apps" do
      other_app = create(:agentic_coding_app)
      create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      resource = build(:agentic_coding_app_resource, :neon_database, agentic_coding_app: other_app)
      expect(resource).to be_valid
    end

    it "allows re-provision after the existing resource is soft-deleted" do
      existing = create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      existing.update!(status: "deleted")

      fresh = build(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect(fresh).to be_valid
      expect { fresh.save! }.not_to raise_error
    end

    it "still blocks duplicates when the existing resource is active" do
      create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app, status: "provisioned")
      dup = build(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect(dup).not_to be_valid
      expect(dup.errors[:resource_type]).to include("has already been taken")
    end

    it "enforces the partial unique index at the DB level" do
      create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect do
        described_class.new(
          agentic_coding_app: app,
          resource_type: "neon_database",
          status: "provisioned"
        ).save!(validate: false)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "status" do
    it "defaults to provisioning" do
      resource = described_class.new
      expect(resource.status).to eq("provisioning")
    end

    it "rejects invalid status" do
      resource = build(:agentic_coding_app_resource, status: "invalid")
      expect(resource).not_to be_valid
    end
  end

  describe "credentials serialization" do
    let(:app) { create(:agentic_coding_app) }

    it "stores and retrieves credentials as a Hash" do
      resource = create(:agentic_coding_app_resource, :neon_database,
                        agentic_coding_app: app,
                        credentials: { "database_url" => "postgresql://test" })
      expect(resource.reload.credentials).to be_a(Hash)
      expect(resource.credentials["database_url"]).to eq("postgresql://test")
    end
  end
end
