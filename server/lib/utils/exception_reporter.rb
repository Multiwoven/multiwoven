# frozen_string_literal: true

module Utils
  class ExceptionReporter
    def self.report(exception, meta = {})
      # Multiple APM can be supported based on the ENV
      if ENV["APPSIGNAL_PUSH_API_KEY"]
        Appsignal.send_error(exception) do |transaction|
          transaction.set_tags(meta)
        end

      elsif ENV["NEW_RELIC_KEY"]
        NewRelic::Agent.notice_error(exception)
      end
    end
  end
end
