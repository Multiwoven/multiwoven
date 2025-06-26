
module Admin
  class WorkspaceMembersController < Admin::BaseController
    skip_before_action :authenticate_super_admin!
    skip_before_action :verify_authenticity_token
    before_action :set_workspace, only: [:create]
    
    def create
      return if performed? # Stop if redirect already happened in before_action
      
      email = params[:email]
      user = User.find_by(email: email)
      member_role = Role.find_by(role_name: "Member")
      
      if user.nil?
        flash_error("User not found with email: #{email}")
      elsif @workspace.users.exists?(user.id)
        flash_error("User is already a member of this workspace.")
      elsif member_role.nil?
        flash_error("Member role not found.")
      else
        workspace_user = WorkspaceUser.new(
          workspace: @workspace,
          user: user,
          role: member_role
        )
        
        if workspace_user.save
          session[:success_message] = "User added successfully"
        else
          flash_error(workspace_user.errors.full_messages.to_sentence)
        end
      end
      
      redirect_back(fallback_location: admin_root_path)
    end
    
    private
    
    def set_workspace
      @workspace = Workspace.find_by(id: params[:workspace_id])
      unless @workspace
        session[:error_message] = "Workspace not found."
        redirect_back(fallback_location: admin_root_path)
      end
    end
    
    def flash_error(message)
      session[:error_message] = message
    end
  end
end