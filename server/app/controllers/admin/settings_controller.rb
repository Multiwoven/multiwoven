# frozen_string_literal: true

module Admin
  class SettingsController < Admin::BaseController
    skip_before_action :verify_authenticity_token, only: [:update_password]
    
    def index
      # Transfer any messages from session to instance variables for display
      @error_message = session.delete(:error_message)
      @success_message = session.delete(:success_message)
    end
    
    def update_password
      @super_admin = current_super_admin
      
      unless @super_admin.authenticate(password_params[:old_password])
        session[:error_message] = "Old password does not match!"
        return redirect_to admin_setting_index_path
      end
      
      if @super_admin.update(
        password: password_params[:new_password],
        password_confirmation: password_params[:password_confirmation]
      )
        session[:success_message] = "Password updated successfully!"
      else
        session[:error_message] = @super_admin.errors.full_messages.to_sentence
      end
      
      redirect_to admin_setting_index_path
    end
    
    private
    
    def password_params
      params.permit(:old_password, :new_password, :password_confirmation)
    end
  end
end