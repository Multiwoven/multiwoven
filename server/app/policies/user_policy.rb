# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def me?
    true
  end
end
