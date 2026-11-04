# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpendingLimitAlert, type: :model do
  let(:counter) { create(:spending_limit_counter) }

  describe "validations" do
    it "is valid with a threshold inside the alert range" do
      expect(build(:spending_limit_alert, spending_limit_counter: counter, threshold: 80)).to be_valid
    end

    it "accepts 100, which is the cap itself rather than a configured threshold" do
      expect(build(:spending_limit_alert, spending_limit_counter: counter, threshold: 100)).to be_valid
    end

    it "refuses a threshold above the cap" do
      alert = build(:spending_limit_alert, spending_limit_counter: counter, threshold: 101)

      expect(alert).not_to be_valid
      expect(alert.errors[:threshold]).to be_present
    end

    it "refuses a missing threshold rather than letting the not-null constraint raise" do
      alert = build(:spending_limit_alert, spending_limit_counter: counter, threshold: nil)

      expect(alert).not_to be_valid
      expect(alert.errors[:threshold]).to be_present
    end
  end

  describe "one row per counter and threshold" do
    it "reads as a validation error rather than a database exception" do
      create(:spending_limit_alert, spending_limit_counter: counter, threshold: 80)

      expect { create(:spending_limit_alert, spending_limit_counter: counter, threshold: 80) }
        .to raise_error(ActiveRecord::RecordInvalid, /Threshold has already been taken/)
    end

    # Two writers can both pass the validation, so the index has to be what actually refuses.
    it "is still enforced by the database when the validation is bypassed" do
      create(:spending_limit_alert, spending_limit_counter: counter, threshold: 80)

      expect { described_class.new(spending_limit_counter: counter, threshold: 80).save!(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same threshold on a different counter" do
      other = create(:spending_limit_counter)
      create(:spending_limit_alert, spending_limit_counter: counter, threshold: 80)

      expect(build(:spending_limit_alert, spending_limit_counter: other, threshold: 80)).to be_valid
    end
  end

  describe ".pending" do
    it "returns only the rows that have not been delivered" do
      undelivered = create(:spending_limit_alert, spending_limit_counter: counter, threshold: 80)
      create(:spending_limit_alert, :delivered, spending_limit_counter: counter, threshold: 90)

      expect(described_class.pending).to contain_exactly(undelivered)
    end
  end

  describe "cleanup" do
    it "goes when its counter goes, including through delete_all" do
      alert = create(:spending_limit_alert, spending_limit_counter: counter, threshold: 80)

      SpendingLimitCounter.where(id: counter.id).delete_all

      expect(described_class.where(id: alert.id)).to be_empty
    end
  end
end
