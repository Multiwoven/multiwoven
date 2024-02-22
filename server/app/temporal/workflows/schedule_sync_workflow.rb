# frozen_string_literal: true

module Workflows
  class ScheduleSyncWorkflow < Temporal::Workflow
    include Activities
    def execute(sync_id)
      ScheduleSyncActivity.execute!(sync_id)
    end
  end
end
