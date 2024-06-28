# frozen_string_literal: true

class SyncRunPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :sync_run)
  end

  def show?
    permitted?(:read, :sync_run)
  end
end
