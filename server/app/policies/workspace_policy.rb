# frozen_string_literal: true

class WorkspacePolicy < ApplicationPolicy
  def index?
    admin? || member? || viewer?
  end

  def show?
    admin? || member? || viewer?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end
end
