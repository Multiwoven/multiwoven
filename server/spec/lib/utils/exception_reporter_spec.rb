# frozen_string_literal: true

require "rails_helper"
RSpec.describe Utils::ExceptionReporter do
  let(:exception) { StandardError.new("Test exception") }

  before do
    allow(Appsignal).to receive(:send_error)
    allow(NewRelic::Agent).to receive(:notice_error)
  end

  context "when APPSIGNAL_PUSH_API_KEY is set" do
    before do
      allow(ENV).to receive(:[]).with("APPSIGNAL_PUSH_API_KEY").and_return("some_key")
      allow(ENV).to receive(:[]).with("NEW_RELIC_KEY").and_return(nil)
    end

    it "sends the error to Appsignal" do
      Utils::ExceptionReporter.report(exception)
      expect(Appsignal).to have_received(:send_error).with(exception)
    end

    it "sends error to Appsignal with meta tags" do
      meta = { key: "value" }
      transaction = instance_double("Appsignal::Transaction")
      allow(Appsignal).to receive(:send_error).and_yield(transaction)
      expect(transaction).to receive(:set_tags).with(meta)
      described_class.report(exception, meta)
    end
  end

  context "when NEW_RELIC_KEY is set" do
    before do
      allow(ENV).to receive(:[]).with("APPSIGNAL_PUSH_API_KEY").and_return(nil)
      allow(ENV).to receive(:[]).with("NEW_RELIC_KEY").and_return("some_key")
    end

    it "sends the error to New Relic" do
      Utils::ExceptionReporter.report(exception)
      expect(NewRelic::Agent).to have_received(:notice_error).with(exception)
    end
  end

  context "when neither APPSIGNAL_PUSH_API_KEY nor NEW_RELIC_KEY is set" do
    before do
      allow(ENV).to receive(:[]).with("APPSIGNAL_PUSH_API_KEY").and_return(nil)
      allow(ENV).to receive(:[]).with("NEW_RELIC_KEY").and_return(nil)
    end

    it "does not send the error to Appsignal or New Relic" do
      Utils::ExceptionReporter.report(exception)
      expect(Appsignal).not_to have_received(:send_error)
      expect(NewRelic::Agent).not_to have_received(:notice_error)
    end
  end
end
