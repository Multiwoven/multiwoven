# frozen_string_literal: true

class ConnectorDefinitionPolicy < ApplicationPolicy
  def index?
    admin? || member? || viewer?
  end

  def show?
    admin? || member? || viewer?
  end

  def check_connection?
    admin? || member?
  end
end
