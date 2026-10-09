# frozen_string_literal: true

if defined?(Appsignal::Transaction)
  Appsignal::Transaction.singleton_class.class_eval do
    alias_method :create_without_string_id, :create

    def create(id, namespace, request, options = {})
      create_without_string_id(id.to_s, namespace, request, options)
    end
  end
end

Rails.application.config.to_prepare do
  next unless defined?(Appsignal::Hooks::ActiveJobHook::ActiveJobClassInstrumentation)

  safety_check = Module.new do
    private

    def transaction_set_error(transaction, exception)
      return unless Appsignal.config[:activejob_report_errors] == "all"
      return if transaction.nil?

      transaction.set_error(exception)
    end
  end

  Appsignal::Hooks::ActiveJobHook::ActiveJobClassInstrumentation.prepend(safety_check)
end
