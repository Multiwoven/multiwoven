# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgenticCoding::App, type: :model do
  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:status) }
    it { should belong_to(:workspace) }
    it { should belong_to(:user) }
    it { should belong_to(:template).class_name("AgenticCoding::Template").optional }
    it { should belong_to(:source_app).class_name("AgenticCoding::App").optional }
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:prompts).dependent(:destroy) }
    it { should have_many(:deployments).dependent(:destroy) }
    it { should have_many(:clones).dependent(:nullify) }
    it { should have_many(:app_resources).dependent(:destroy) }
    it { should have_many(:visitors).class_name("AgenticCoding::AppVisitor").dependent(:destroy) }
    it { should define_enum_for(:status).with_values(draft: 0, published: 1, archived: 2) }
  end

  describe "default status" do
    let(:app) { described_class.new }

    it "sets default status" do
      expect(app.status).to eq("draft")
    end
  end

  describe "template association" do
    it "creates an app from a template" do
      template = create(:agentic_coding_template)
      app = create(:agentic_coding_app, :from_template, template:)

      expect(app.template).to eq(template)
      expect(template.apps).to include(app)
    end

    it "allows app without a template" do
      app = create(:agentic_coding_app)
      expect(app.template).to be_nil
    end

    it "nullifies template_id when template is destroyed" do
      template = create(:agentic_coding_template)
      app = create(:agentic_coding_app, :from_template, template:)

      template.destroy!
      app.reload

      expect(app.template_id).to be_nil
    end
  end

  describe "clone association" do
    it "creates a cloned app" do
      source = create(:agentic_coding_app)
      clone = create(:agentic_coding_app, :cloned, source_app: source)

      expect(clone.source_app).to eq(source)
      expect(source.clones).to include(clone)
    end

    it "allows app without a source" do
      app = create(:agentic_coding_app)
      expect(app.source_app).to be_nil
    end

    it "nullifies source_app_id when source is destroyed" do
      source = create(:agentic_coding_app)
      clone = create(:agentic_coding_app, :cloned, source_app: source)

      source.destroy!
      clone.reload

      expect(clone.source_app_id).to be_nil
    end

    it "supports chained clones" do
      original = create(:agentic_coding_app)
      clone1 = create(:agentic_coding_app, :cloned, source_app: original)
      clone2 = create(:agentic_coding_app, :cloned, source_app: clone1, name: "Clone of Clone")

      expect(clone2.source_app).to eq(clone1)
      expect(clone1.source_app).to eq(original)
      expect(original.clones).to include(clone1)
      expect(clone1.clones).to include(clone2)
    end

    it "counts multiple clones" do
      source = create(:agentic_coding_app)
      3.times { |i| create(:agentic_coding_app, :cloned, source_app: source, name: "Clone #{i}") }

      expect(source.clones.count).to eq(3)
    end
  end

  describe "database helper", if: defined?(AgenticCoding::DatabaseProvisioner) do
    let(:app) { create(:agentic_coding_app) }

    it "returns nil when no database resource exists" do
      expect(app.database).to be_nil
    end

    it "returns the active provider's resource" do
      resource = create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect(app.database).to eq(resource)
    end

    it "does not return s3_storage" do
      create(:agentic_coding_app_resource, :s3_storage, agentic_coding_app: app)
      expect(app.database).to be_nil
    end

    it "keys the lookup off DatabaseProvisioner.resource_type" do
      expect(AgenticCoding::DatabaseProvisioner).to receive(:resource_type).and_return("neon_database")
      resource = create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect(app.database).to eq(resource)
    end
  end

  describe "neon_database alias", if: defined?(AgenticCoding::DatabaseProvisioner) do
    let(:app) { create(:agentic_coding_app) }

    it "behaves identically to #database for back-compat" do
      resource = create(:agentic_coding_app_resource, :neon_database, agentic_coding_app: app)
      expect(app.neon_database).to eq(resource)
      expect(app.neon_database).to eq(app.database)
    end
  end

  describe "cleanup_database callback", if: defined?(AgenticCoding::DatabaseProvisioner) do
    it "calls DatabaseProvisioner.delete_for_app on destroy" do
      app = create(:agentic_coding_app)
      expect(AgenticCoding::DatabaseProvisioner).to receive(:delete_for_app).with(app)
      app.destroy!
    end

    it "does not fail if DatabaseProvisioner raises an error" do
      app = create(:agentic_coding_app)
      allow(AgenticCoding::DatabaseProvisioner).to receive(:delete_for_app).and_raise(StandardError, "API down")
      expect { app.destroy! }.not_to raise_error
    end
  end

  describe "destroying app" do
    let(:app) { create(:agentic_coding_app) }

    it "also destroys associated ahoy visits and events" do
      visitor = create(:agentic_coding_app_visitor, app:)
      visit = Ahoy::Visit.create!(
        visit_token: SecureRandom.hex(16),
        visitor_token: visitor.visitor_token,
        started_at: Time.current
      )
      Ahoy::Event.create!(visit_id: visit.id, name: "$view", properties: {}, time: Time.current)

      expect { app.destroy! }
        .to change(AgenticCoding::AppVisitor, :count).by(-1)
        .and change(Ahoy::Visit, :count).by(-1)
        .and change(Ahoy::Event, :count).by(-1)
    end
  end

  describe "template + clone combo" do
    it "an app from a template can be cloned" do
      template = create(:agentic_coding_template)
      original = create(:agentic_coding_app, :from_template, template:)
      clone = create(:agentic_coding_app, :cloned, source_app: original)

      expect(original.template).to eq(template)
      expect(clone.source_app).to eq(original)
      expect(clone.template).to be_nil
    end
  end
end
