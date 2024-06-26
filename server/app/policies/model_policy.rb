# frozen_string_literal: true

class ModelPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :model)
  end

  def show?
    permitted?(:read, :model)
  end

  def create?
    permitted?(:create, :model)
  end

  def update?
    permitted?(:update, :model)
  end

  def destroy?
    permitted?(:delete, :model)
  end

  def configurations?
    permitted?(:read, :model)
  end
end
