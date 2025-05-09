# frozen_string_literal: true

class ConnectorPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :connector)
  end

  def show?
    permitted?(:read, :connector)
  end

  def create?
    permitted?(:create, :connector)
  end

  def update?
    permitted?(:update, :connector)
  end

  def destroy?
    permitted?(:delete, :connector)
  end

  def discover?
    permitted?(:read, :connector)
  end

  def query_source?
    permitted?(:read, :connector)
  end

  def execute_model?
    permitted?(:read, :connector)
  end
end
