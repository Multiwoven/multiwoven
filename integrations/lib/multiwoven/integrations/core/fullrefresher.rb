# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module Fullrefresher
      def write(sync_config, records, action = "destination_insert")
        if sync_config && sync_config.sync_mode == "full_refresh" && !@full_refreshed
          response = clear_all_records(sync_config)
          return response unless response &&
                                 response.control.status == Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"]

          @full_refreshed = true
        end

        super(sync_config, records, action)
      end
    end
  end
end
