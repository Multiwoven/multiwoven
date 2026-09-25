# frozen_string_literal: true

class SpendingLimitPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :spending_limit)
  end

  def show?
    permitted?(:read, :spending_limit)
  end

  def create?
    permitted?(:create, :spending_limit)
  end

  def update?
    permitted?(:update, :spending_limit)
  end

  def destroy?
    permitted?(:delete, :spending_limit)
  end
end
