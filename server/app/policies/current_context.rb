# frozen_string_literal: true

class CurrentContext
  attr_reader :user, :workspace

  def initialize(user, workspace)
    @user = user
    @workspace = workspace
  end
end
