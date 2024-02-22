# frozen_string_literal: true

module Syncs
  class UpdateSync
    include Interactor

    def call
      unless context
             .sync
             .update(context.sync_params)
        context.fail!(sync: context.sync)
      end
    end
  end
end
