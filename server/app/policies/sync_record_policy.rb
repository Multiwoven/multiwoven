# frozen_string_literal: true

class SyncRecordPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :sync_record)
  end
end
