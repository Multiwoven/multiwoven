# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :context, :user, :workspace, :record

  def initialize(context, record)
    @user = context.user
    @workspace = context.workspace
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def admin?
    workspace_user = workspace.workspace_users.find_by(user:)
    workspace_user&.admin? || false
  end

  def member?
    workspace_user = workspace.workspace_users.find_by(user:)
    workspace_user&.member? || false
  end

  def viewer?
    workspace_user = workspace.workspace_users.find_by(user:)
    workspace_user&.viewer? || false
  end
end
