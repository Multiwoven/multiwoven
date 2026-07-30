# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Appsignal Active Job nil transaction fix (initializer)" do
  before do
    raise "Appsignal::Transaction not defined — is the gem loaded?" unless defined?(Appsignal::Transaction)
  end

  describe "Transaction.create converts id to String" do
    it "passes a string id to the original create (fails if monkey patch is removed)" do
      expect(Appsignal::Transaction).to respond_to(:create_without_string_id),
                                        "Appsignal::Transaction does not respond to :create_without_string_id — " \
                                          "the alias_method monkey patch in the initializer may have been removed"

      allow(Appsignal::Transaction).to receive(:create_without_string_id).and_return(nil)

      Appsignal::Transaction.create(123, :active_job, nil, {})

      expect(Appsignal::Transaction).to have_received(:create_without_string_id)
        .with("123", :active_job, nil, {})
    end
  end

  describe "transaction_set_error with nil transaction" do
    before do
      unless defined?(Appsignal::Hooks::ActiveJobHook::ActiveJobClassInstrumentation)
        raise "Appsignal::Hooks::ActiveJobHook::ActiveJobClassInstrumentation not defined " \
              "— is the appsignal gem loaded?"
      end
    end

    it "does not raise when transaction is nil (fails if monkey patch is removed)" do
      instrumentation = Appsignal::Hooks::ActiveJobHook::ActiveJobClassInstrumentation
      instance = Class.new { include instrumentation }.new

      expect(instance.private_methods).to include(:transaction_set_error),
                                          "Expected instance to have private method :transaction_set_error — " \
                                            "the safety module may no longer be prepended in the initializer"

      exception = StandardError.new("job error")
      allow(Appsignal).to receive(:config).and_return({ activejob_report_errors: "all" })

      expect { instance.send(:transaction_set_error, nil, exception) }.not_to raise_error
    end
  end
end
