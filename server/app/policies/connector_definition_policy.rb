# frozen_string_literal: true

class ConnectorDefinitionPolicy < ApplicationPolicy
  def index?
    permitted?(:read, :connector_definition)
  end

  def show?
    permitted?(:read, :connector_definition)
  end

  def check_connection?
    permitted?(:create, :connector_definition)
  end
end
