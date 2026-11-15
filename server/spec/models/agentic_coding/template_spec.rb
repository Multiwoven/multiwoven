# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::Template, type: :model do
  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:image_id) }
    it { should validate_presence_of(:status) }
    it { should have_many(:apps).dependent(:nullify) }
    it { should define_enum_for(:status).with_values(draft: 0, active: 1, archived: 2) }

    it "enforces unique name" do
      create(:agentic_coding_template, name: "Unique Template")
      duplicate = build(:agentic_coding_template, name: "Unique Template")
      expect(duplicate).not_to be_valid
    end

    it "enforces unique slug" do
      create(:agentic_coding_template, slug: "unique-slug")
      duplicate = build(:agentic_coding_template, name: "Other Template", slug: "unique-slug")
      expect(duplicate).not_to be_valid
    end

    it "assigns a canonical default slug from known template names" do
      template = build(:agentic_coding_template, name: "KPI Monitoring Dashboard", slug: nil)
      expect(template).to be_valid
      expect(template.slug).to eq("kpi-monitoring")
    end

    it "assigns a parameterized slug when no canonical default exists" do
      template = build(:agentic_coding_template, name: "My Custom Board", slug: nil)
      expect(template).to be_valid
      expect(template.slug).to eq("my-custom-board")
    end

    it "requires slug when it cannot be derived from name" do
      template = build(:agentic_coding_template, name: nil, slug: nil)
      expect(template).not_to be_valid
      expect(template.errors[:slug]).to include("can't be blank")
    end
  end

  describe "default status" do
    let(:template) { described_class.new }

    it "sets default status to draft" do
      expect(template.status).to eq("draft")
    end
  end

  describe ".active_templates" do
    let!(:active_template) { create(:agentic_coding_template, status: :active) }
    let!(:draft_template) { create(:agentic_coding_template, :draft, name: "Draft Template") }
    let!(:archived_template) { create(:agentic_coding_template, :archived, name: "Archived Template") }

    it "returns only active templates" do
      result = described_class.active_templates
      expect(result).to include(active_template)
      expect(result).not_to include(draft_template)
      expect(result).not_to include(archived_template)
    end
  end

  describe "associations" do
    it "nullifies apps when template is destroyed" do
      template = create(:agentic_coding_template)
      app = create(:agentic_coding_app, :from_template, template:)

      template.destroy!
      app.reload

      expect(app.template).to be_nil
      expect(app.template_id).to be_nil
    end
  end
end
