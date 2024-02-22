# frozen_string_literal: true

# spec/interactors/workspaces/list_all_spec.rb

require "rails_helper"

RSpec.describe Workspaces::ListAll, type: :interactor do
  let!(:user) { create(:user) }
  let!(:workspace1) { create(:workspace) }
  let!(:workspace2) { create(:workspace) }

  describe ".call" do
    before do
      # Link the user to the workspaces
      create(:workspace_user, workspace: workspace1, user:)
      create(:workspace_user, workspace: workspace2, user:)
    end

    it "lists all workspaces for the user" do
      result = Workspaces::ListAll.call(user:)

      expect(result).to be_a_success
      expect(result.workspaces).to contain_exactly(workspace1, workspace2)
    end
  end
end
