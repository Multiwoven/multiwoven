# frozen_string_literal: true

module Activities
  class LoaderActivity < Temporal::Activity
    def execute(sync_run_id)
      # TODO: Select loader strategy
      # based on destination sync mode
      loader = ReverseEtl::Loaders::Standard.new
      loader.write(sync_run_id)
    end
  end
end
