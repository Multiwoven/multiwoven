# frozen_string_literal: true

module Activities
  class LoaderActivity < Temporal::Activity
    timeouts(
      start_to_close: (ENV["TEMPORAL_ACTIVITY_START_TO_CLOSE"] || "3600").to_i
    )
    def execute(sync_run_id)
      # TODO: Select loader strategy
      # based on destination sync mode
      loader = ReverseEtl::Loaders::Standard.new
      loader.write(sync_run_id)
    end
  end
end
