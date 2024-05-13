# frozen_string_literal: true

# app/interactors/workspaces/list_all.rb
module Workspaces
  class Find
    include Interactor

    def call
      context.workspace = context.user.workspaces.find_by(id: context.id)
    end
  end
end
