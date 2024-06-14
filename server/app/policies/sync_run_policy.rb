# frozen_string_literal: true

class SyncRunPolicy < ApplicationPolicy
  def index?
    admin? || member? || viewer?
  end

  def show?
    admin? || member? || viewer?
  end
end
