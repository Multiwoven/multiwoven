# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :report)
  end
end
