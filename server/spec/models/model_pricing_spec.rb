# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModelPricing, type: :model do
  describe "validations" do
    subject { build(:model_pricing) }

    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:model) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:effective_from) }
    it { should validate_inclusion_of(:currency).in_array(described_class::SUPPORTED_CURRENCIES) }
    it { should validate_numericality_of(:input_rate).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:output_rate).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:cache_read_rate).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:cache_write_rate).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { should define_enum_for(:source).with_values(%i[sync manual]) }
  end

  describe "the window a rate is in force for" do
    it "refuses a window that closes before it opens" do
      pricing = build(:model_pricing, effective_from: Time.current, effective_to: 1.day.ago)

      expect(pricing).not_to be_valid
      expect(pricing.errors[:effective_to]).to include("must be after effective_from")
    end

    it "refuses a window that closes the instant it opens" do
      moment = Time.current
      pricing = build(:model_pricing, effective_from: moment, effective_to: moment)

      expect(pricing).not_to be_valid
    end

    it "accepts an open ended window" do
      expect(build(:model_pricing, effective_from: 1.day.ago, effective_to: nil)).to be_valid
    end
  end

  describe "scopes" do
    let(:provider) { "OpenAI" }
    let(:model) { "gpt-4.1-mini" }

    it "returns the row in force at the given moment" do
      old = create(:model_pricing, provider:, model:, effective_from: 10.days.ago, effective_to: 5.days.ago)
      current = create(:model_pricing, provider:, model:, effective_from: 5.days.ago, effective_to: nil)

      expect(described_class.in_force_at(7.days.ago)).to contain_exactly(old)
      expect(described_class.in_force_at(Time.current)).to contain_exactly(current)
    end

    it "treats the closing moment as outside the window" do
      closed_at = 5.days.ago
      old = create(:model_pricing, provider:, model:, effective_from: 10.days.ago, effective_to: closed_at)

      expect(described_class.in_force_at(closed_at)).not_to include(old)
    end

    it "returns only the rows that were never closed" do
      open_row = create(:model_pricing, provider:, model:)
      create(:model_pricing, :closed, provider:, model:)

      expect(described_class.in_force).to contain_exactly(open_row)
    end

    it "narrows to one provider and model" do
      wanted = create(:model_pricing, provider:, model:)
      create(:model_pricing, provider: "Anthropic", model:)
      create(:model_pricing, provider:, model: "gpt-4o")

      expect(described_class.for_model(provider, model)).to contain_exactly(wanted)
    end
  end

  describe "#same_rates?" do
    let(:pricing) do
      build(:model_pricing, input_rate: "0.0000030", output_rate: "0.0000120", cache_read_rate: 0,
                            cache_write_rate: 0)
    end

    it "is true when every rate matches, whatever the form it arrives in" do
      rates = { input_rate: "0.000003", output_rate: BigDecimal("0.000012"), cache_read_rate: 0,
                cache_write_rate: nil }

      expect(pricing.same_rates?(rates)).to be(true)
    end

    it "is false when a single rate has moved" do
      rates = { input_rate: "0.0000031", output_rate: "0.0000120", cache_read_rate: 0, cache_write_rate: 0 }

      expect(pricing.same_rates?(rates)).to be(false)
    end
  end
end
