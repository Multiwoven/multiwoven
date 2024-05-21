# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :workspace

  def initialize(user, workspace)
    @user = user
    @workspace = workspace
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

  class Scope
    attr_reader :user, :worksapce, :scope

    def initialize(user, scope)
      @user = user
      @worksapce = worksapce
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end
  end
end
