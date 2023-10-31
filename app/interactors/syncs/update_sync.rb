# frozen_string_literal: true

module Syncs
  class UpdateSync
    include Interactor

    def call
      unless context
             .sync
             .update(context.sync_params)
        context.fail!(errors: context.sync.errors)
      end
    end
  end
end
