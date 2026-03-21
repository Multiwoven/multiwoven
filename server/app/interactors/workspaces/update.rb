# frozen_string_literal: true

# app/interactors/workspaces/update.rb

module Workspaces
  class Update
    include Interactor

    def call
      workspace = context.user.workspaces.find_by(id: context.id)
      return context.fail!(workspace:) if workspace.blank?

      workspace.slug = "default" if workspace.slug.empty?
      if workspace.update(context.workspace_params)
        context.workspace = workspace
      else
        context.fail!(workspace:)
      end
    end
  end
end
