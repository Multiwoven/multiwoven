# frozen_string_literal: true

class SyncPolicy < ApplicationPolicy
  def create?
    admin? || member?
  end

  def update?
    admin? || member?
  end
end
