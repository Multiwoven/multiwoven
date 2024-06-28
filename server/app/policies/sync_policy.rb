# frozen_string_literal: true

class SyncPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :sync)
  end

  def show?
    permitted?(:read, :sync)
  end

  def create?
    permitted?(:create, :sync)
  end

  def update?
    permitted?(:update, :sync)
  end

  def destroy?
    permitted?(:delete, :sync)
  end

  def configurations?
    permitted?(:read, :sync)
  end
end
