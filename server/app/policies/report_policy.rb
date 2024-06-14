# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def index?
    admin? || member? || viewer?
  end
end
