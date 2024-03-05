# frozen_string_literal: true

# == Schema Information
#
# Table name: syncs
#
#  id                :bigint           not null, primary key
#  workspace_id      :integer
#  source_id         :integer
#  model_id          :integer
#  destination_id    :integer
#  configuration     :jsonb
#  source_catalog_id :integer
#  schedule_type     :integer
#  schedule_data     :jsonb
#  status            :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require "rails_helper"

RSpec.describe Sync, type: :model do
  it { should validate_presence_of(:workspace_id) }
  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:destination_id) }
  it { should validate_presence_of(:model_id) }
  it { should validate_presence_of(:configuration) }
  it { should validate_presence_of(:schedule_type) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:sync_interval) }
  it { should validate_presence_of(:sync_interval_unit) }

  it { should define_enum_for(:schedule_type).with_values(manual: 0, automated: 1) }
  it { should define_enum_for(:status).with_values(disabled: 0, healthy: 1, pending: 2, failed: 3, aborted: 4) }
  it { should define_enum_for(:sync_mode).with_values(full_refresh: 0, incremental: 1) }

  it { should belong_to(:workspace) }
  it { should belong_to(:source).class_name("Connector") }
  it { should belong_to(:destination).class_name("Connector") }
  it { should belong_to(:model) }
  it { should have_many(:sync_runs).dependent(:destroy) }

  describe "#to_protocol" do
    let(:streams) do
      [
        { "name" => "profile", "batch_support" => false, "batch_size" => 1, "json_schema" => {} },
        { "name" => "customer", "batch_support" => false, "batch_size" => 1, "json_schema" => {} }
      ]
    end

    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) do
      create(:catalog, connector: destination,
                       catalog: {
                         "request_rate_limit" => 60,
                         "request_rate_limit_unit" => "minute",
                         "request_rate_concurrency" => 2,
                         "streams" => streams
                       })
    end

    let(:sync) { create(:sync, destination:) }

    it "returns sync config protocol" do
      protocol = sync.to_protocol
      expect(protocol).to be_a(Multiwoven::Integrations::Protocol::SyncConfig)
    end
  end

  describe "#schedule_cron_expression" do
    let(:sync) { build(:sync, sync_interval:, sync_interval_unit:) }

    context "when interval unit is hours" do
      let(:sync_interval) { 3 }
      let(:sync_interval_unit) { "hours" }

      it "returns the correct cron expression" do
        expect(sync.schedule_cron_expression).to eq("0 */3 * * *")
      end
    end

    context "when interval unit is days" do
      let(:sync_interval) { 1 }
      let(:sync_interval_unit) { "days" }

      it "returns the correct cron expression" do
        expect(sync.schedule_cron_expression).to eq("0 0 */1 * *")
      end
    end

    context "when interval unit is invalid" do
      let(:sync_interval) { 1 }
      let(:sync_interval_unit) { "invalid" }

      it "raises an ArgumentError" do
        expect do
          sync.schedule_cron_expression
        end.to raise_error(ArgumentError, "'invalid' is not a valid sync_interval_unit")
      end
    end
  end

  describe "#schedule_sync" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { build(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }

    before do
      allow(Temporal).to receive(:start_workflow).and_return(true)
    end

    context "when a new record is created" do
      it "schedules a sync workflow" do
        sync.schedule_sync
        expect(Temporal).to have_received(:start_workflow).with(
          Workflows::ScheduleSyncWorkflow,
          sync.id
        )
      end
    end

    context "when an existing record is updated" do
      it "schedules a sync workflow if sync interval changes" do
        sync.sync_interval = 1
        sync.save(validate: false)
        expect(Temporal).to have_received(:start_workflow).with(
          Workflows::ScheduleSyncWorkflow,
          sync.id
        )
      end

      it "does not schedule a sync workflow if sync interval does not change" do
        sync.primary_key = "primary_key"
        sync.save
        expect(Temporal).not_to have_received(:start_workflow)
      end
    end
  end

  describe "#default_scope" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create_list(:sync, 4, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }

    context "when a multiple syncs are created" do
      it "returns the syncs in descending order of updated_at" do
        expect(Sync.all).to eq(sync.sort_by(&:updated_at).reverse)
      end
    end

    context "when a sync is updated" do
      it "returns the syncs in descending order of updated_at" do
        sync.first.update(updated_at: DateTime.current + 1.week)
        sync.last.update(updated_at: DateTime.current - 1.week)

        expect(Sync.all).to eq(sync.sort_by(&:updated_at).reverse)
      end
    end
  end

  describe "AASM states" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }

    it "starts in pending state" do
      expect(sync).to have_state(:pending)
    end

    it "transitions from pending to healthy" do
      expect(sync).to transition_from(:pending).to(:healthy).on_event(:complete)
    end

    it "transitions from pending to failed" do
      expect(sync).to transition_from(:pending).to(:failed).on_event(:fail)
    end

    it "transitions from any state to disabled" do
      expect(sync).to transition_from(:pending).to(:disabled).on_event(:disable)
    end

    it "transitions from any state to disabled" do
      sync.complete
      expect(sync).to transition_from(:healthy).to(:disabled).on_event(:disable)
    end

    it "transitions from disabled to pending" do
      sync.disable
      expect(sync).to transition_from(:disabled).to(:pending).on_event(:enable)
    end

    describe "#set_defaults" do
      let(:new_sync) { Sync.new }

      it "sets default values" do
        expect(new_sync.status).to eq("pending")
      end
    end

    describe "AASM states" do
      let(:source) do
        create(:connector, connector_type: "source", connector_name: "Snowflake")
      end
      let(:destination) { create(:connector, connector_type: "destination") }
      let!(:catalog) { create(:catalog, connector: destination) }
      let(:sync) { create(:sync, sync_interval: 3, sync_interval_unit: "hours", source:, destination:) }
      context "when transition is allowed" do
        it "starts in pending state" do
          expect(sync).to have_state(:pending)
        end

        it "transitions from pending to healthy" do
          expect(sync).to transition_from(:pending).to(:healthy).on_event(:complete)
          expect(sync).to have_state(:healthy)
        end

        it "transitions from pending to failed" do
          expect(sync).to transition_from(:pending).to(:failed).on_event(:fail)
          expect(sync).to have_state(:failed)
        end

        it "transitions from healthy to failed" do
          expect(sync).to transition_from(:healthy).to(:failed).on_event(:fail)
          expect(sync).to have_state(:failed)
        end

        it "transitions from any healthy to disabled" do
          expect(sync).to transition_from(:pending).to(:disabled).on_event(:disable)
          expect(sync).to have_state(:disabled)
        end

        it "transitions from any state to disabled" do
          sync.complete
          expect(sync).to transition_from(:healthy).to(:disabled).on_event(:disable)
          expect(sync).to have_state(:disabled)
        end
      end

      context "when transition is not allowed" do
        it "does not transition from disable to healthy directly" do
          sync.complete
          expect(sync).to have_state(:healthy)
          expect(sync).to transition_from(:healthy).to(:disabled).on_event(:disable)
          expect(sync).to have_state(:disabled)
          expect do
            sync.complete
          end.to raise_error(AASM::InvalidTransition)
          expect(sync).to have_state(:disabled)
        end
        it "does not transition from healthy to pending directly" do
          sync.complete
          expect(sync).to have_state(:healthy)
          expect do
            sync.enable
          end.to raise_error(AASM::InvalidTransition)
          expect(sync).to have_state(:healthy)
        end
      end
    end
  end
end
