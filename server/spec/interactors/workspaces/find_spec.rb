# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workspaces::Find, type: :interactor do
  let!(:user) { create(:user) }
  let!(:workspace) { create(:workspace) }

  describe ".call" do
    before do
      create(:workspace_user, workspace:, user:)
    end

    it "lists all workspaces for the user" do
      result = Workspaces::Find.call(id: workspace.id, user:)
      expect(result).to be_a_success
      expect(result.workspace).to eq(workspace)
    end
  end
end
