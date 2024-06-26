# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :context, :user, :workspace, :record, :permissions

  def initialize(context, record)
    @user = context.user
    @workspace = context.workspace
    @record = record
    @permissions = role_permissions
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

  private

  def role_permissions
    workspace_user = workspace.workspace_users.find_by(user:)
    role = workspace_user&.role

    role ? role.policies["permissions"] : {}
  end

  def permitted?(action, resource)
    permissions = role_permissions
    permissions.dig(resource.to_s, action.to_s) || false
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
