# frozen_string_literal: true

class WorkspacePolicy < ApplicationPolicy
  def index?
    permitted?(:read, :workspace)
  end

  def show?
    permitted?(:read, :workspace)
  end

  def create?
    permitted?(:create, :workspace)
  end

  def update?
    permitted?(:update, :workspace)
  end

  def destroy?
    permitted?(:delete, :workspace)
  end
end
