# frozen_string_literal: true

class SyncRecordPolicy < ApplicationPolicy
  def index?
    admin? || member? || viewer?
  end
end
