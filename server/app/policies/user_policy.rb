# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def me?
    admin? || member? || viewer?
  end
end
