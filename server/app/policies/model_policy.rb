# frozen_string_literal: true

class ModelPolicy < ApplicationPolicy
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

  def configurations?
    admin? || member?
  end
end
