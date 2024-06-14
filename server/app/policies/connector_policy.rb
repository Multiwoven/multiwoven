# frozen_string_literal: true

class ConnectorPolicy < ApplicationPolicy
  def index?
    admin? || member? || viewer?
  end

  def show?
    admin? || member? || viewer?
  end

  def create?
    admin? || member?
  end

  def update?
    admin? || member?
  end

  def destroy?
    admin? || member?
  end

  def discover?
    admin? || member? || viewer?
  end

  def query_source?
    admin? || member? || viewer?
  end
end
